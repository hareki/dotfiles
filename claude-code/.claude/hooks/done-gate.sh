#!/bin/bash
# Sourced first by the Stop hooks that act only once the main agent is done. Stop also fires
# while background subagents, workflows, or shells are in flight, so end the hook until none
# are left. Shells count because a subagent waiting on its own shell is listed as that shell
# alone. Pending scheduled runs don't count: they would hold every hook back.

# Shells that never end on their own (dev servers) would hold every hook back too, so these
# commands are skipped. Add one here when the hooks go quiet while it is up
long_lived='http-server|(nx|ng) serve|npm (run )?start|node dist/main'

jq -e --arg long_lived "$long_lived" 'any(.background_tasks[]?;
  .type == "subagent" or .type == "workflow"
  or (.type == "shell" and (.command | test($long_lived) | not)))' >/dev/null && exit 0
