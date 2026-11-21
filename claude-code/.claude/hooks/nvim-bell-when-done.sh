#!/bin/bash
# Rings the bell only once the main agent is done, and only for a Claude started in an nvim
# terminal, which has no bell of its own (bell.sh)

. "$(dirname "$0")/done-gate.sh"

# Checked only once the gate has read the payload: a hook that exits before Claude Code
# finishes writing it fails with EPIPE. A background session has its daemon's environment, so
# it rings when the Claude that started the daemon ran in nvim, like nvim-when-done.sh
[ -n "$NVIM" ] || exit 0

# Muted by the `ctb` zsh function
[ -e "$HOME/.local/state/claude-code/bell-muted" ] && exit 0

. "$(dirname "$0")/bell.sh" "$@"
