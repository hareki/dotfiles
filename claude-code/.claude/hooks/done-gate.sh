#!/bin/bash
# Sourced first by the Stop hooks that act only once the main agent is done. Stop also fires
# while background subagents, workflows, or shells are in flight, so end the hook until none
# are left. Shells count because a subagent waiting on its own shell is listed as that shell
# alone. Pending scheduled runs don't count: they would hold every hook back. Nor do teammates
# and cloud sessions, which stay listed as running while it is the user they wait on.

# Shells that never end on their own (dev servers) would hold every hook back too, so these
# commands are skipped. Add one here when the hooks go quiet while it is up. A package
# manager's options and workspace may come before its script, which is `start` or `dev` up to
# a separator (`start:api`, `dev_lite`, not `devtools`)
long_lived='http-server\b(?![./-])|\b(nx|ng|firebase) serve|\bnx run \S+:serve|\bnest start|\b(npx|bunx)( +-\S+)* +vite\b(?![.-]| +(build|optimize))|\b(p?npm|yarn|bun)( +(-\S+( +[^-\s;&|]\S*)?|workspace +\S+|run))* +(start|dev)(?![a-z])|node dist/main\b(?!-)|--remote-debugging-port'

# A server sent to the background with `&` is not what its shell waits on: that shell ends with
# what follows the `&`, unless another server or a `wait` does
detached='\s&\s(?![\s\S]*(\bwait\b|'"$long_lived"'))'

payload=$(</dev/stdin)

# The payload clips a command at 1000 characters, which can hide a server's name. The whole of
# a clipped one is in the transcripts, among the Bash calls that ran in the background
if [[ $payload == *'… [+'*' chars]'* ]]; then
  transcript=$(jq -r '.transcript_path' <<<"$payload")
  ran=$(/opt/homebrew/bin/rg -INF --no-ignore '"run_in_background":true' "$transcript" "${transcript%.jsonl}" 2>/dev/null |
    jq -cn '[inputs | .message.content[]? | select(.type == "tool_use") | .input.command | strings]')
fi

jq -e --arg long_lived "$long_lived" --arg detached "$detached" --argjson ran "${ran:-[]}" '
  # Reruns of one script begin alike, so the length the clip marker gives picks among them
  def whole: (capture("^(?<head>[\\s\\S]*)… \\[\\+(?<cut>[0-9]+) chars\\]$") // null) as $clip
    | if $clip == null then . else
        ([$ran[] | select(startswith($clip.head))]
          | min_by(length - ($clip.head | length) - ($clip.cut | tonumber) | fabs)) // .
      end;
  # pkill and pgrep name a server only to find it
  def launched: gsub("\\bp(kill|grep)\\b([^\\n;&|]|\\|(?!\\|))*"; "");
  any(.background_tasks[]?;
    .type == "subagent" or .type == "workflow"
    or (.type == "shell" and (.command | whole | launched | (test($long_lived) | not) or test($detached))))
' <<<"$payload" >/dev/null && exit 0
