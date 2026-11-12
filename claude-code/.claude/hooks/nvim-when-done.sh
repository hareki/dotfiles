#!/bin/bash
# Tells nvim once the main agent is done, so its statusline can flag that while the agent's
# panel is hidden

. "$(dirname "$0")/done-gate.sh"

# The server of the nvim whose terminal started this Claude; one started anywhere else has
# none. A background session has its daemon's environment instead, so it reaches the nvim of
# the Claude that started the daemon, if any
[ -n "$NVIM" ] || exit 0

# Backgrounded with its streams detached, like bell.sh's afplay: a busy nvim answers late, and
# Claude holds the turn open until the hook exits
/opt/homebrew/bin/nvim --headless --server "$NVIM" --remote-expr "v:lua.require'features.ai.claudecode-nvim.done'.mark()" </dev/null >/dev/null 2>&1 &
