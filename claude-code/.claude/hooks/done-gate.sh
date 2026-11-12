#!/bin/bash
# Sourced first by the Stop hooks that act only once the main agent is done: ends the hook
# while it isn't. Stop also fires when it ends a turn just to wait on background subagents or
# workflows, and again each time one of them reports back. The payload lists that in-flight
# work, so stay quiet until none is left. Background shells and pending scheduled runs don't
# count: a dev server would hold every hook back, and each scheduled run should get through.

jq -e 'any(.background_tasks[]?; .type == "subagent" or .type == "workflow")' >/dev/null && exit 0
