#!/bin/bash

# Re-enable sleep when Claude is actually done, not merely between turns
# Stop also fires while Claude waits on its own background work (async agents,
# workflows, run_in_background shells), so releasing on it unconditionally drops
# the assertion mid-task; the release is gated on a work-in-flight check instead
#
# That check runs detached: the pending counts live in the transcript's
# turn_duration entry, which Claude writes only once every Stop hook has returned

hooks_dir=${0%/*}
[ "$hooks_dir" = "$0" ] && hooks_dir=.
source "$hooks_dir/sleep-assertion.sh"

# jq on this PATH is a mise shim that redoes mise's whole tool resolution on
# every call: measured ~105ms against ~4ms for a real binary. That is paid once
# synchronously per Stop, and again on each of the 12 poll iterations below
JQ=/usr/bin/jq
[ -x "$JQ" ] || JQ=jq

# Kill the caffeinate we were spawned for, but only while it is still this
# session's sole assertion: any re-arm since has replaced it with a new pid, and
# a second pid means a concurrent arm is in flight. Naming one exact pid is what
# makes this safe without a mutex, since the pid we kill is either already dead
# or already superseded, and any mismatch holds and lets the next event retry
release() {
    [ "$(ours_pids "$1")" = "$2" ] || return
    kill "$2" 2>/dev/null
}

# The bounded degradation for a detector that cannot run at all: the full lease
# is traded for one that cannot outlive FALLBACK_SECONDS, so a detector broken
# by a future Claude Code change never pins the Mac awake for the session.
# Only ever applied to a full lease, because re-degrading an already degraded
# assertion would push its deadline back on every event and bound nothing
degrade() {
    local held
    held=$(ours_pids "$1" "$HELD_SECONDS")
    [ -n "$held" ] || return
    # $2, when given, is the generation the caller was spawned for; without it
    # whatever full lease the session holds now is the one to degrade
    [ -z "$2" ] || [ "$held" = "$2" ] || return
    arm "$1" "$FALLBACK_SECONDS"
}

# Reads transcript lines on stdin, emits nothing when no turn_duration is
# present, or (given a nonzero $1) when the newest one does not postdate that
# epoch, since a count written before this generation armed describes an older
# turn. The compare is deliberately inclusive: entry epochs and the arming epoch
# are both whole seconds, so a same-second entry reads as stale and over-holds
# (bounded) rather than ever releasing on a previous turn's count.
# fromjson? drops the half-written line a concurrent append can leave in range,
# which a plain slurp would fail the whole read on. The select has to run before
# the last, so that a line merely mentioning turn_duration cannot displace the
# real entry
pending_count() {
    grep 'turn_duration' |
        "$JQ" -R -n --argjson since "${1:-0}" '
            last(inputs | fromjson? | select(.subtype == "turn_duration"))
            | if . == null then empty
              elif $since > 0
                  and (((.timestamp | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601)? // 0)
                      <= $since)
              then empty
              else (.pendingBackgroundAgentCount // 0) + (.pendingWorkflowCount // 0)
              end' 2>/dev/null
}

if [ "$1" = "--deferred" ]; then
    claude_pid="$2"
    caffeinate_pid="$3"
    since="$4"
    hook_event="$5"
    transcript="$6"
    offset="$7"

    pending=""
    if [ "$hook_event" = "Stop" ]; then
        # Wait for the turn_duration entry this turn is about to append. A missing
        # offset means the size read failed, so nothing can be waited for.
        # The offset anchors this positionally rather than by timestamp on
        # purpose: entry timestamps are whole seconds, so a turn whose last tool
        # call and turn end land in the same second could never be dated apart
        tries=0
        while [ -n "$offset" ] && [ "$tries" -lt 12 ]; do
            pending=$(tail -c "+$((offset + 1))" "$transcript" 2>/dev/null | pending_count)
            if [ -n "$pending" ]; then
                break
            fi
            tries=$((tries + 1))
            sleep 1
        done
    elif [ -n "$since" ]; then
        # idle_prompt: no fresh entry is owed, so read the newest one on file,
        # but only trust it if it postdates this generation's arming (taken from
        # the caffeinate's own start time); an older entry belongs to a previous
        # turn. With no anchor at all nothing on file can be trusted, which
        # falls through to the unknowable case below
        pending=$(pending_count "$since" < "$transcript")
    fi

    # A count that is not a plain integer is a count we cannot reason about
    case "$pending" in
        *[!0-9]*) pending="" ;;
    esac

    if [ -z "$pending" ]; then
        # The count is unknowable: on Stop the entry this turn owed us never
        # landed; on idle_prompt nothing on file postdates the last arming (seen
        # live when a resumed session's stale transcript released mid-task while
        # a background agent was still working). Hold, but on the bounded lease
        degrade "$claude_pid" "$caffeinate_pid"
        exit 0
    fi

    if [ "$pending" -eq 0 ]; then
        # Background shells are not counted by pendingBackgroundAgentCount, so probe
        # for them separately; this argv matches Bash-tool shells and nothing else
        if ! pgrep -qfP "$claude_pid" 'shell-snapshots/snapshot-'; then
            release "$claude_pid" "$caffeinate_pid"
        fi
    fi
    exit 0
fi

handle_event() {
    local pids hook_event transcript caffeinate_pid since offset

    pids=$(ours_pids "$PPID")
    [ -n "$pids" ] || return

    # One call for both fields, since even a real jq is a fork worth halving
    {
        IFS= read -r hook_event
        IFS= read -r transcript
    } < <(echo "$input" | "$JQ" -r '(.hook_event_name // ""), (.transcript_path // "")' 2>/dev/null)

    if [ "$hook_event" = "SessionEnd" ]; then
        # The session is going away, so none of its work can still be in flight
        # and every generation it still owns is ours to kill
        kill $pids 2>/dev/null
        return
    fi

    if [ -z "$hook_event" ] || [ ! -f "$transcript" ]; then
        # The payload itself is unreadable (schema change, broken jq shim)
        # or the transcript is gone: the deferred detector cannot run, and
        # the bounded degradation must not hide behind it
        degrade "$PPID"
        return
    fi

    # Past here a release is on the table, and a release has to name one exact
    # pid. Two of them means a concurrent arm is in flight, so hold and let the
    # next event retry once arm() has collapsed them
    case "$pids" in
        *[!0-9]*) return ;;
    esac
    caffeinate_pid=$pids

    # Only Stop appends a fresh turn_duration to wait for; idle_prompt reads the
    # newest entry on file and needs the arming epoch to date it against
    offset=""
    since=""
    if [ "$hook_event" = "Stop" ]; then
        offset=$(stat -f '%z' "$transcript" 2>/dev/null)
    else
        since=$(arm_epoch "$caffeinate_pid")
    fi

    nohup bash "$0" --deferred "$PPID" "$caffeinate_pid" "$since" \
        "$hook_event" "$transcript" "$offset" > /dev/null 2>&1 < /dev/null &
}

input=$(cat)
# echo "$input" > /tmp/allow_sleep_debug.json # hook payload debug info

handle_event

# Every outcome above is a normal one, including deciding to do nothing, so the
# hook must not report the last guard's status as a failure
exit 0
