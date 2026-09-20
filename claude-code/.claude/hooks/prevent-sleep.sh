#!/bin/bash

# Keep Mac awake (system + display) during active Claude Code turns
# One caffeinate per session, tied to the Claude process via -w so it
# self-exits if Claude crashes
#
# Wired to UserPromptSubmit and PreToolUse: tool calls re-arm the assertion so
# turns resumed without a prompt (permission dialogs, background-agent wakes)
# are covered too. That makes this a liveness heartbeat rather than a state
# transition, so it is one idempotent refresh with nothing to read back and
# nothing to branch on, which is what keeps the per-tool-call path cheap

# Parameter expansion rather than dirname: a fork is 2ms, which is 10% of this
# hook, and it is paid on every tool call
hooks_dir=${0%/*}
[ "$hooks_dir" = "$0" ] && hooks_dir=.
source "$hooks_dir/sleep-assertion.sh"

arm "$PPID" "$HELD_SECONDS"
