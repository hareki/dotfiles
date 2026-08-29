#!/bin/bash

# Re-enable sleep when Claude is actually done, not merely between turns
# Stop also fires while Claude waits on its own background work (async agents,
# workflows, run_in_background shells), so releasing on it unconditionally drops
# the assertion mid-task; the release is gated on a work-in-flight check instead
#
# That check runs detached: the pending counts live in the transcript's
# turn_duration entry, which Claude writes only once every Stop hook has returned

source "$(dirname "$0")/sleep-lock.sh"

# Kill the caffeinate we were spawned for, unless a newer turn already re-armed;
# the token is re-checked under the session lock so a re-arm can no longer land
# between the check and the kill
release() {
    lock_session "$1" || return
    if [ "$(marker_token "$1")" = "$3" ]; then
        if [ -n "$(caffeinate_kind "$2" "$1")" ]; then
            kill "$2" 2>/dev/null
        fi
        rm -f "$SESSIONS_DIR/$1"
    fi
    unlock_session "$1"
}

# SessionEnd's reaper: the session is dying, so whatever pid the marker records
# is ours to kill regardless of which generation (or in-flight swap) wrote it
release_final() {
    local pid
    lock_session "$1" || return
    pid=$(cat "$SESSIONS_DIR/$1" 2>/dev/null)
    if [ -n "$pid" ] && [ -n "$(caffeinate_kind "$pid" "$1")" ]; then
        kill "$pid" 2>/dev/null
    fi
    rm -f "$SESSIONS_DIR/$1"
    unlock_session "$1"
}

# The bounded degradation for a detector that cannot run at all: whatever held
# assertion the marker records is traded for a fallback that cannot outlive
# FALLBACK_SECONDS, so a broken payload never pins the display for the session
swap_to_fallback() {
    local pid
    lock_session "$1" || return
    pid=$(cat "$SESSIONS_DIR/$1" 2>/dev/null)
    if [ -n "$pid" ] && [ "$(caffeinate_kind "$pid" "$1")" = "held" ]; then
        spawn_fallback "$1"
        kill "$pid" 2>/dev/null
    fi
    unlock_session "$1"
}

# Reads transcript lines on stdin, emits nothing when no turn_duration is
# present, or (given a nonzero $1) when the newest one predates that epoch,
# since a count written before this generation armed describes an older turn.
# The compare is deliberately strict: entry epochs are whole seconds while the
# arming mtime keeps its fraction, so a same-second entry reads as stale and
# over-holds (bounded) rather than ever releasing on a previous turn's count.
# fromjson? drops the half-written line a concurrent append can leave in range,
# which a plain slurp would fail the whole read on
pending_count() {
    grep 'turn_duration' |
        jq -R -s --arg since "${1:-0}" '
            split("\n") | map(fromjson? | select(.subtype == "turn_duration")) | last
            | if . == null then empty
              elif ($since | tonumber) > 0
                  and (((.timestamp | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601)? // 0)
                      < ($since | tonumber))
              then empty
              else (.pendingBackgroundAgentCount // 0) + (.pendingWorkflowCount // 0)
              end' 2>/dev/null
}

if [ "$1" = "--deferred" ]; then
    claude_pid="$2"
    caffeinate_pid="$3"
    token="$4"
    hook_event="$5"
    transcript="$6"
    offset="$7"

    pending=""
    if [ "$hook_event" = "Stop" ]; then
        # Wait for the turn_duration entry this turn is about to append. A missing
        # offset means the size read failed, so nothing can be waited for
        tries=0
        while [ -n "$offset" ] && [ "$tries" -lt 12 ]; do
            pending=$(tail -c "+$((offset + 1))" "$transcript" 2>/dev/null | pending_count)
            if [ -n "$pending" ]; then
                break
            fi
            tries=$((tries + 1))
            sleep 1
        done
    else
        # idle_prompt: no fresh entry is owed, so read the newest one on file,
        # but only trust it if it postdates this generation's arming (the marker
        # mtime rides in the token); an older entry belongs to a previous turn
        pending=$(pending_count "${token##*|}" < "$transcript")
    fi

    # A count that is not a plain integer is a count we cannot reason about
    case "$pending" in
        *[!0-9]*) pending="" ;;
    esac

    if [ -z "$pending" ]; then
        # The count is unknowable: on Stop the entry this turn owed us never
        # landed; on idle_prompt nothing on file postdates the last arming (seen
        # live when a resumed session's stale transcript released mid-task while
        # a background agent was still working). Hold, but swap in a bounded
        # assertion, since a detector broken by a future Claude Code change must
        # not pin the Mac awake for the session
        if lock_session "$claude_pid"; then
            if [ "$(marker_token "$claude_pid")" = "$token" ] &&
                [ "$(caffeinate_kind "$caffeinate_pid" "$claude_pid")" = "held" ]; then
                spawn_fallback "$claude_pid"
                kill "$caffeinate_pid" 2>/dev/null
            fi
            unlock_session "$claude_pid"
        fi
        exit 0
    fi

    if [ "$pending" -eq 0 ]; then
        # Background shells are not counted by pendingBackgroundAgentCount, so probe
        # for them separately; this argv matches Bash-tool shells and nothing else
        shells=$(ps -eo ppid,args 2>/dev/null | awk -v p="$claude_pid" '$1 == p' |
            grep -c 'shell-snapshots/snapshot-')
        if [ "$shells" -eq 0 ]; then
            release "$claude_pid" "$caffeinate_pid" "$token"
        fi
    fi
    exit 0
fi

input=$(cat)
# echo "$input" > /tmp/allow_sleep_debug.json # hook payload debug info

if [ -d "$SESSIONS_DIR" ]; then
    if [ -f "$SESSIONS_DIR/$PPID" ]; then
        # One jq call for both fields: the mise shim costs ~21ms against ~3ms
        {
            IFS= read -r hook_event
            IFS= read -r transcript
        } < <(echo "$input" | jq -r '(.hook_event_name // ""), (.transcript_path // "")' 2>/dev/null)

        if [ "$hook_event" = "SessionEnd" ]; then
            # The session is going away, so none of its work can still be in flight
            release_final "$PPID"
        elif [ -n "$hook_event" ] && [ -f "$transcript" ]; then
            # pid and mtime are read under the lock so the token can never mix
            # two generations (a re-arm touch landing between the two reads)
            if lock_session "$PPID"; then
                caffeinate_pid=$(cat "$SESSIONS_DIR/$PPID" 2>/dev/null)
                token="$caffeinate_pid|$(stat -f '%Fm' "$SESSIONS_DIR/$PPID" 2>/dev/null)"
                unlock_session "$PPID"
                if [ -n "$caffeinate_pid" ]; then
                    # Only Stop appends a fresh turn_duration to wait for
                    offset=""
                    if [ "$hook_event" = "Stop" ]; then
                        offset=$(stat -f '%z' "$transcript" 2>/dev/null)
                    fi
                    nohup bash "$0" --deferred "$PPID" "$caffeinate_pid" "$token" \
                        "$hook_event" "$transcript" "$offset" > /dev/null 2>&1 &
                fi
            fi
        else
            # The payload itself is unreadable (schema change, broken jq shim)
            # or the transcript is gone: the deferred detector cannot run, and
            # the bounded degradation must not hide behind it
            swap_to_fallback "$PPID"
        fi
    fi

    clean_stale_sessions
fi
