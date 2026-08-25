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
    case "$sid" in
        '' | *[!0-9]*) continue ;;
    esac
    if ! ps -p "$sid" -o comm= 2>/dev/null | grep -q 'claude'; then
        rm -f "$f"
    fi
done

# Already have this session's own caffeinate? (PPID = Claude Code's node process)
# Matching exact argv matters twice over: Claude Code runs a caffeinate of its own,
# and allow-sleep.sh's bounded fallback has to be upgraded back to -w here
if [ -f "$SESSIONS_DIR/$PPID" ]; then
    pid=$(cat "$SESSIONS_DIR/$PPID" 2>/dev/null)
    args=$(ps -p "$pid" -o args= 2>/dev/null)
    if [ "$args" = "caffeinate -d -i -w $PPID" ]; then
        exit 0
    fi
    case "$args" in
        "caffeinate -d -i -t "*) kill "$pid" 2>/dev/null ;;
    esac
fi

# -d keeps the display on (Amphetamine-style), -i prevents idle system sleep
nohup caffeinate -d -i -w "$PPID" > /dev/null 2>&1 &
echo $! > "$SESSIONS_DIR/$PPID.tmp"
mv "$SESSIONS_DIR/$PPID.tmp" "$SESSIONS_DIR/$PPID"
