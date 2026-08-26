#!/bin/bash

# Shared state for prevent-sleep.sh and allow-sleep.sh: where the per-session
# markers live, which caffeinate argv counts as ours, and the stale-session GC
#
# Sourced, never executed, so $PPID still resolves to Claude Code's own process

LOCK_DIR="/tmp/claude_caffeinate"
SESSIONS_DIR="$LOCK_DIR/sessions"

# How long the bounded fallback holds for when the pending count is unreadable
FALLBACK_SECONDS=1800

# Claude Code runs a caffeinate of its own, so ours is matched on exact argv
HELD_ARGS="caffeinate -d -i -w"
FALLBACK_ARGS="caffeinate -d -i -t $FALLBACK_SECONDS"

is_ours() {
    local args
    args=$(ps -p "$1" -o args= 2>/dev/null)
    [ "$args" = "$HELD_ARGS $2" ] || [ "$args" = "$FALLBACK_ARGS" ]
}

is_fallback() {
    [ "$(ps -p "$1" -o args= 2>/dev/null)" = "$FALLBACK_ARGS" ]
}

# Generation token for a session's marker. prevent-sleep.sh reuses a live
# caffeinate instead of replacing it, so the recorded pid alone cannot tell a
# re-armed turn from the one a deferred release was spawned for; the mtime can
marker_token() {
    printf '%s|%s' "$(cat "$SESSIONS_DIR/$1" 2>/dev/null)" \
        "$(stat -f '%Fm' "$SESSIONS_DIR/$1" 2>/dev/null)"
}

# Drop markers whose Claude process is gone. A -w caffeinate is reaped for us,
# but the bounded fallback is not tied to that process, so it is killed here
clean_stale_sessions() {
    local f sid pid
    for f in "$SESSIONS_DIR"/*; do
        [ -f "$f" ] || continue
        sid=$(basename "$f")
        case "$sid" in
            '' | *[!0-9]*) continue ;;
        esac
        if ! ps -p "$sid" -o comm= 2>/dev/null | grep -q 'claude'; then
            pid=$(cat "$f" 2>/dev/null)
            if [ -n "$pid" ] && is_fallback "$pid"; then
                kill "$pid" 2>/dev/null
            fi
            rm -f "$f"
        fi
    done
}
