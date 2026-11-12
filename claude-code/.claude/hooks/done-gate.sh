#!/bin/bash
# Sourced first by the Stop hooks that act only once the main agent is done. Stop also fires
# while background subagents or workflows are in flight, so end the hook until none are left.
# Background shells and pending scheduled runs don't count: either would hold every hook back.

jq -e 'any(.background_tasks[]?; .type == "subagent" or .type == "workflow")' >/dev/null && exit 0
