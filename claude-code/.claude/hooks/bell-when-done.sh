#!/bin/bash
# Rings the bell only once the main agent is done

. "$(dirname "$0")/done-gate.sh"

# Muted by the `ctb` zsh function. Checked only once the gate's jq has read the payload: a
# hook that exits before Claude Code finishes writing it fails with EPIPE
[ -e "$HOME/.local/state/claude-code/bell-muted" ] && exit 0

. "$(dirname "$0")/bell.sh" "$@"
