#!/bin/bash

# Shared state for prevent-sleep.sh and allow-sleep.sh: which caffeinate argv
# counts as ours, how long an assertion may live, and how to arm one
#
# There is no state on disk. A session's assertion IS its caffeinate process:
# the argv carries the Claude pid, so the process table answers both "does this
# session hold one" and "which generation is it". A marker file could disagree
# with reality in a way the process table cannot, and its worst case was
# unrecoverable: a lost marker left a caffeinate nothing could ever kill
#
# Sourced, never executed, so $PPID still resolves to Claude Code's own process

# How long an assertion holds without further evidence. The full lease outlasts
# any legitimate gap between hook events (one long tool call, or Claude idling
# on a background shell); the degraded one bounds a detector broken by a future
# Claude Code change, which must not pin the display for the whole session
HELD_SECONDS=86400
FALLBACK_SECONDS=1800

# Claude Code runs a caffeinate of its own, so ours is matched on exact argv.
# -d keeps the display on (Amphetamine-style), -i prevents idle system sleep;
# the trailing -w <claude pid> does double duty, making the argv session-unique
# (no other session's release can mistake it for its own) and self-reaping on
# Claude exit. arm() builds its spawn from this same string, so the argv that is
# matched and the argv that is spawned can never drift apart
OURS_ARGS="caffeinate -d -i -t"

# Every live assertion this session owns, one pid per line, optionally narrowed
# to a single lease ($2). Empty when it owns none
ours_pids() {
    pgrep -f -x "$OURS_ARGS ${2:-[0-9]+} -w $1" 2>/dev/null
}

# Replace this session's assertion with a fresh one on the given lease. Spawn
# before kill, so the assertion is never momentarily absent. Replacing rather
# than reusing is what makes the pid a generation token, upgrades a degraded
# lease back to a full one, and collapses a duplicate left by two concurrent
# tool calls, all without a check-then-act to serialize
arm() {
    local old
    old=$(ours_pids "$1")
    nohup $OURS_ARGS "$2" -w "$1" > /dev/null 2>&1 < /dev/null &
    [ -n "$old" ] && kill $old 2>/dev/null
    return 0
}

# When a pid armed, as a whole-second unix epoch: the freshness anchor a
# deferred release needs to tell this generation's turn_duration entry from an
# older turn's. lstart is the only spelling macOS ps offers here (no etimes)
arm_epoch() {
    local started
    started=$(ps -p "$1" -o lstart= 2>/dev/null)
    [ -n "$started" ] || return
    date -j -f '%a %b %d %T %Y' "$started" +%s 2>/dev/null
}
