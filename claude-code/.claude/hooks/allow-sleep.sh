#!/bin/bash

# Re-enable sleep when Claude is actually done, not merely between turns
# Stop also fires while Claude waits on its own background work (async agents,
# workflows, run_in_background shells), so releasing on it unconditionally drops
# the assertion mid-task; the release is gated on a work-in-flight check instead
#
# That check runs detached: the pending counts live in the transcript's
# turn_duration entry, which Claude writes only once every Stop hook has returned

source "$(dirname "$0")/sleep-lock.sh"

# Kill the caffeinate we were spawned for, unless a newer turn already re-armed
release() {
    if [ "$(marker_token "$1")" != "$3" ]; then
        return
    fi
    if is_ours "$2" "$1"; then
        kill "$2" 2>/dev/null
    fi
    rm -f "$SESSIONS_DIR/$1"
}

# Reads transcript lines on stdin, emits nothing when no turn_duration is present.
# fromjson? drops the half-written line a concurrent append can leave in range,
# which a plain slurp would fail the whole read on
pending_count() {
    grep 'turn_duration' |
        jq -R -s 'split("\n") | map(fromjson? | select(.subtype == "turn_duration")) | last
                  | if . == null then empty
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
        # idle_prompt: no further turn is coming, so read the newest entry on file
        pending=$(pending_count 2>/dev/null < "$transcript")
    fi

    # A count that is not a plain integer is a count we cannot reason about
    case "$pending" in
        *[!0-9]*) pending="" ;;
    esac

    if [ -z "$pending" ] && [ "$hook_event" = "Stop" ]; then
        # The entry this turn owed us never landed, so the count is unknowable:
        # hold, but swap in a bounded assertion, since a detector broken by a
        # future Claude Code change must not pin the Mac awake for the session
        if [ "$(marker_token "$claude_pid")" != "$token" ]; then
            exit 0
        fi
        if ! is_ours "$caffeinate_pid" "$claude_pid"; then
            exit 0
        fi
        if is_fallback "$caffeinate_pid"; then
            exit 0
        fi
        nohup caffeinate -d -i -t "$FALLBACK_SECONDS" > /dev/null 2>&1 &
        echo $! > "$SESSIONS_DIR/$claude_pid.tmp"
        mv "$SESSIONS_DIR/$claude_pid.tmp" "$SESSIONS_DIR/$claude_pid"
        kill "$caffeinate_pid" 2>/dev/null
        exit 0
    fi

    # Background shells are not counted by pendingBackgroundAgentCount, so probe
    # for them separately; this argv matches Bash-tool shells and nothing else
    shells=$(ps -eo ppid,args 2>/dev/null | awk -v p="$claude_pid" '$1 == p' |
        grep -c 'shell-snapshots/snapshot-')

    # An absent count on idle_prompt is not an unreadable one: no turn_duration on
    # file means no turn has ever completed, so nothing can still be pending
    if [ "${pending:-0}" -eq 0 ] && [ "$shells" -eq 0 ]; then
        release "$claude_pid" "$caffeinate_pid" "$token"
    fi
    exit 0
fi

input=$(cat)
# echo "$input" > /tmp/allow_sleep_debug.json # hook payload debug info

if [ -d "$SESSIONS_DIR" ]; then
    caffeinate_pid=$(cat "$SESSIONS_DIR/$PPID" 2>/dev/null)

    if [ -n "$caffeinate_pid" ]; then
        # One jq call for both fields: the mise shim costs ~21ms against ~3ms
        {
            IFS= read -r hook_event
            IFS= read -r transcript
        } < <(echo "$input" | jq -r '(.hook_event_name // ""), (.transcript_path // "")' 2>/dev/null)

        token=$(marker_token "$PPID")
        if [ "$hook_event" = "SessionEnd" ]; then
            # The session is going away, so none of its work can still be in flight
            release "$PPID" "$caffeinate_pid" "$token"
        elif [ -n "$hook_event" ] && [ -f "$transcript" ]; then
            # Only Stop appends a fresh turn_duration to wait for
            offset=""
            if [ "$hook_event" = "Stop" ]; then
                offset=$(wc -c < "$transcript" 2>/dev/null | tr -d ' ')
            fi
            nohup bash "$0" --deferred "$PPID" "$caffeinate_pid" "$token" \
                "$hook_event" "$transcript" "$offset" > /dev/null 2>&1 &
        fi
    fi

    clean_stale_sessions
fi
