#!/bin/bash

# Re-enable sleep when Claude is actually done, not merely between turns
# Stop also fires while Claude waits on its own background work (async agents,
# workflows, run_in_background shells), so releasing on it unconditionally drops
# the assertion mid-task; the release is gated on a work-in-flight check instead
#
# That check runs detached: the pending counts live in the transcript's
# turn_duration entry, which Claude writes only once every Stop hook has returned

LOCK_DIR="/tmp/claude_caffeinate"
SESSIONS_DIR="$LOCK_DIR/sessions"

# How long the bounded fallback holds for when the pending count is unreadable
FALLBACK_SECONDS=1800

# Claude Code runs a caffeinate of its own, so ours is matched on exact argv
is_ours() {
    local args
    args=$(ps -p "$1" -o args= 2>/dev/null)
    [ "$args" = "caffeinate -d -i -w $2" ] ||
        [ "$args" = "caffeinate -d -i -t $FALLBACK_SECONDS" ]
}

# Kill the caffeinate we were spawned for, unless a newer turn already re-armed
release() {
    if [ "$(cat "$SESSIONS_DIR/$1" 2>/dev/null)" != "$2" ]; then
        return
    fi
    if is_ours "$2" "$1"; then
        kill "$2" 2>/dev/null
    fi
    rm -f "$SESSIONS_DIR/$1"
}

# Reads transcript lines on stdin, emits nothing when no turn_duration is present
pending_count() {
    jq -s 'map(select(.subtype == "turn_duration")) | last
           | if . == null then empty
             else (.pendingBackgroundAgentCount // 0) + (.pendingWorkflowCount // 0)
             end' 2>/dev/null
}

if [ "$1" = "--deferred" ]; then
    claude_pid="$2"
    caffeinate_pid="$3"
    transcript="$4"
    offset="$5"

    pending=""
    if [ -n "$offset" ]; then
        # Stop: wait for the turn_duration entry this turn is about to append
        tries=0
        while [ "$tries" -lt 12 ]; do
            pending=$(tail -c "+$((offset + 1))" "$transcript" 2>/dev/null | pending_count)
            if [ -n "$pending" ]; then
                break
            fi
            tries=$((tries + 1))
            sleep 1
        done
    else
        # idle_prompt: no further turn is coming, so read the newest entry on file
        pending=$(tail -n 2000 "$transcript" 2>/dev/null | pending_count)
    fi

    # Background shells are not counted by pendingBackgroundAgentCount, so probe
    # for them separately; this argv matches Bash-tool shells and nothing else
    shells=$(ps -eo ppid,args 2>/dev/null | awk -v p="$claude_pid" '$1 == p' |
        grep -c 'shell-snapshots/snapshot-')

    if [ -z "$pending" ]; then
        # Count unreadable, so hold but swap in a bounded assertion: a detector
        # broken by a future Claude Code change must not be able to pin the Mac
        # awake for the rest of the session
        if [ "$(cat "$SESSIONS_DIR/$claude_pid" 2>/dev/null)" != "$caffeinate_pid" ]; then
            exit 0
        fi
        if ! is_ours "$caffeinate_pid" "$claude_pid"; then
            exit 0
        fi
        if [ "$(ps -p "$caffeinate_pid" -o args= 2>/dev/null)" = "caffeinate -d -i -t $FALLBACK_SECONDS" ]; then
            exit 0
        fi
        nohup caffeinate -d -i -t "$FALLBACK_SECONDS" > /dev/null 2>&1 &
        echo $! > "$SESSIONS_DIR/$claude_pid.tmp"
        mv "$SESSIONS_DIR/$claude_pid.tmp" "$SESSIONS_DIR/$claude_pid"
        kill "$caffeinate_pid" 2>/dev/null
        exit 0
    fi

    if [ "$pending" -eq 0 ] && [ "$shells" -eq 0 ]; then
        release "$claude_pid" "$caffeinate_pid"
    fi
    exit 0
fi

input=$(cat)
# echo "$input" > /tmp/allow_sleep_debug.json # hook payload debug info

if [ -d "$SESSIONS_DIR" ]; then
    caffeinate_pid=$(cat "$SESSIONS_DIR/$PPID" 2>/dev/null)
    hook_event=$(echo "$input" | jq -r '.hook_event_name // empty')
    transcript=$(echo "$input" | jq -r '.transcript_path // empty')

    if [ -n "$caffeinate_pid" ]; then
        if [ "$hook_event" = "SessionEnd" ]; then
            # The session is going away, so none of its work can still be in flight
            release "$PPID" "$caffeinate_pid"
        elif [ -f "$transcript" ]; then
            # Only Stop appends a fresh turn_duration to wait for
            offset=""
            if [ "$hook_event" = "Stop" ]; then
                offset=$(wc -c < "$transcript" 2>/dev/null | tr -d ' ')
            fi
            nohup bash "$0" --deferred "$PPID" "$caffeinate_pid" "$transcript" "$offset" > /dev/null 2>&1 &
        fi
    fi

    # Clean up stale sessions (Claude process gone; -w already reaped their caffeinate)
    for f in "$SESSIONS_DIR"/*; do
        [ -f "$f" ] || continue
        sid=$(basename "$f")
        case "$sid" in
            '' | *[!0-9]*) continue ;;
        esac
        if ! ps -p "$sid" -o comm= 2>/dev/null | grep -q 'claude'; then
            rm -f "$f"
        fi
    done
fi
