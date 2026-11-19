#!/bin/bash
# Sourced first by the Stop hooks that act only once the main agent is done. Stop also fires
# while background subagents, workflows, or shells are in flight, so end the hook until none
# are left. Shells count because a subagent waiting on its own shell is listed as that shell
# alone. Pending scheduled runs don't count: they would hold every hook back.

# Shells that never end on their own (dev servers) would hold every hook back too, so these
# commands are skipped. Add one here when the hooks go quiet while it is up
long_lived='http-server\b(?![./-])|\b(nx|ng|firebase) serve|\bnest start|\b(p?npm|yarn|bun) (run )?(start|dev)|node dist/main\b(?!-)|--remote-debugging-port'

# A server sent to the background with `&` is not what its shell waits on: that shell ends with
# what follows the `&`, unless another server or a `wait` does
detached='\s&\s(?![\s\S]*(\bwait\b|'"$long_lived"'))'

jq -e --arg long_lived "$long_lived" --arg detached "$detached" 'any(.background_tasks[]?;
  .type == "subagent" or .type == "workflow"
  or (.type == "shell" and (.command | (test($long_lived) | not) or test($detached))))' >/dev/null && exit 0
