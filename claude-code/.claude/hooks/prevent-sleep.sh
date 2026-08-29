#!/bin/bash

# Keep Mac awake (system + display) during active Claude Code turns
# One caffeinate per session, tied to the Claude process via -w so it
# self-exits if Claude crashes; the marker file holds the caffeinate pid
#
# Wired to UserPromptSubmit and PreToolUse: tool calls re-arm the assertion so
# turns resumed without a prompt (permission dialogs, background-agent wakes)
# are covered too, which keeps the fast path below per-tool-call cheap

source "$(dirname "$0")/sleep-lock.sh"

mkdir -p "$SESSIONS_DIR"

# No lock means no safe mutation this event; the next tool call retries
lock_session "$PPID" || exit 0
trap 'unlock_session "$PPID"' EXIT

# Already have this session's own caffeinate? (PPID = Claude Code's node process)
# Matching exact argv matters twice over: Claude Code runs a caffeinate of its
# own, and allow-sleep.sh's bounded fallback has to be upgraded back to -w here
pid=$(cat "$SESSIONS_DIR/$PPID" 2>/dev/null)
if [ -n "$pid" ]; then
    kind=$(caffeinate_kind "$pid" "$PPID")
    if [ "$kind" = "held" ]; then
        # Keeping it, but the marker still has to move: a deferred release left
        # over from the previous turn keys off this token and must not fire now
        touch "$SESSIONS_DIR/$PPID"
        exit 0
    fi
    if [ "$kind" = "fallback" ]; then
        kill "$pid" 2>/dev/null
    fi
fi

clean_stale_sessions

# -d keeps the display on (Amphetamine-style), -i prevents idle system sleep
spawn_held "$PPID"
exit 0
