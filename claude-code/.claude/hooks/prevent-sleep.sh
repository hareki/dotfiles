#!/bin/bash

# Keep Mac awake (system + display) during active Claude Code turns
# One caffeinate per session, tied to the Claude process via -w so it
# self-exits if Claude crashes; the marker file holds the caffeinate pid

LOCK_DIR="/tmp/claude_caffeinate"
SESSIONS_DIR="$LOCK_DIR/sessions"

mkdir -p "$SESSIONS_DIR"

# Clean up stale sessions (Claude process gone; -w already reaped their caffeinate)
for f in "$SESSIONS_DIR"/*; do
    [ -f "$f" ] || continue
    sid=$(basename "$f")
    if ! ps -p "$sid" > /dev/null 2>&1; then
        rm -f "$f"
    fi
done

# Already have a live caffeinate for this session? (PPID = Claude Code's node process)
if [ -f "$SESSIONS_DIR/$PPID" ]; then
    pid=$(cat "$SESSIONS_DIR/$PPID")
    if ps -p "$pid" -o args= 2>/dev/null | grep -q '^caffeinate'; then
        exit 0
    fi
fi

# -d keeps the display on (Amphetamine-style), -i prevents idle system sleep
nohup caffeinate -d -i -w "$PPID" > /dev/null 2>&1 &
echo $! > "$SESSIONS_DIR/$PPID"
