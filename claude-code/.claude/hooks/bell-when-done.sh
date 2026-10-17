#!/bin/bash
# Rings the bell only once the main agent is done. Stop also fires when it ends a
# turn just to wait on background subagents or workflows, and again each time one
# of them reports back. The payload lists that in-flight work, so stay quiet until
# none is left. Background shells and pending scheduled runs don't count: a dev
# server would mute every bell, and each scheduled run should ring.

# `jq` first on $PATH is a mise shim, which costs ~115ms per spawn against ~3ms
# for the real binary.
jq_bin=/opt/homebrew/bin/jq
[ -x "$jq_bin" ] || jq_bin=jq

"$jq_bin" -e 'any(.background_tasks[]?; .type == "subagent" or .type == "workflow")' >/dev/null && exit 0

exec bash "$(dirname "$0")/bell.sh" "$@"
