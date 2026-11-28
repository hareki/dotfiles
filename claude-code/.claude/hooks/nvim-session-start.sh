#!/bin/bash
# Tells nvim which session this Claude runs, so the agent panel of the next nvim in that
# directory resumes it (nvim's `features/ai/claudecode-nvim/session.lua`)

# The server of the nvim whose terminal started this Claude; one started anywhere else has none
[ -n "$NVIM" ] || exit 0

{
  read -r session_id
  read -r transcript
} < <(jq -r '.session_id, .transcript_path')

# A quote is doubled inside the expression's strings
transcript=${transcript//\'/\'\'}

# nvim keeps the report only from its panel's Claude, which it knows by pid: a Claude the panel's
# own started, or a background session's daemon, has the same $NVIM. Backgrounded with its streams
# detached, like nvim-when-done.sh: Claude holds its start until the hook exits
/opt/homebrew/bin/nvim --headless --server "$NVIM" --remote-expr "v:lua.require'features.ai.claudecode-nvim.session'.report('$session_id', '$transcript', '$CLAUDE_PID')" </dev/null >/dev/null 2>&1 &
