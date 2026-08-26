#!/bin/bash

# Keep Mac awake (system + display) during active Claude Code turns
# One caffeinate per session, tied to the Claude process via -w so it
# self-exits if Claude crashes; the marker file holds the caffeinate pid

source "$(dirname "$0")/sleep-lock.sh"

mkdir -p "$SESSIONS_DIR"

clean_stale_sessions

# Already have this session's own caffeinate? (PPID = Claude Code's node process)
# Matching exact argv matters twice over: Claude Code runs a caffeinate of its own,
# and allow-sleep.sh's bounded fallback has to be upgraded back to -w here
if [ -f "$SESSIONS_DIR/$PPID" ]; then
    pid=$(cat "$SESSIONS_DIR/$PPID" 2>/dev/null)
    if [ "$(ps -p "$pid" -o args= 2>/dev/null)" = "$HELD_ARGS $PPID" ]; then
        # Keeping it, but the marker still has to move: a deferred release left
        # over from the previous turn keys off this token and must not fire now
        touch "$SESSIONS_DIR/$PPID"
        exit 0
    fi
    if is_fallback "$pid"; then
        kill "$pid" 2>/dev/null
    fi
fi

# -d keeps the display on (Amphetamine-style), -i prevents idle system sleep
nohup caffeinate -d -i -w "$PPID" > /dev/null 2>&1 &
echo $! > "$SESSIONS_DIR/$PPID.tmp"
mv "$SESSIONS_DIR/$PPID.tmp" "$SESSIONS_DIR/$PPID"
