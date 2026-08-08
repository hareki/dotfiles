#!/bin/bash

# Re-enable sleep when a Claude Code turn ends
# Kills this session's caffeinate, removes its marker, cleans stale sessions

LOCK_DIR="/tmp/claude_caffeinate"
SESSIONS_DIR="$LOCK_DIR/sessions"

[ ! -d "$SESSIONS_DIR" ] && exit 0

# Kill this session's caffeinate (only if the recorded pid is still caffeinate)
if [ -f "$SESSIONS_DIR/$PPID" ]; then
    pid=$(cat "$SESSIONS_DIR/$PPID")
    if ps -p "$pid" -o args= 2>/dev/null | grep -q '^caffeinate'; then
        kill "$pid" 2>/dev/null
    fi
    rm -f "$SESSIONS_DIR/$PPID"
fi

# Clean up stale sessions (Claude process gone; -w already reaped their caffeinate)
for f in "$SESSIONS_DIR"/*; do
    [ -f "$f" ] || continue
    sid=$(basename "$f")
    if ! ps -p "$sid" > /dev/null 2>&1; then
        rm -f "$f"
    fi
done

# Remove the lock dir when no sessions remain
if [ -z "$(find "$SESSIONS_DIR" -type f 2>/dev/null | head -1)" ]; then
    rm -rf "$LOCK_DIR"
fi
