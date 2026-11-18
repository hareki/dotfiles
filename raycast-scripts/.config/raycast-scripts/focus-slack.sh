#!/bin/zsh -f

# @raycast.schemaVersion 1
# @raycast.title Focus Slack
# @raycast.mode silent
# @raycast.packageName Ardia
# @raycast.icon 💼

# Sends Ardia's control socket the requests `ardia tabs --json` and `ardia tabs
# activate` would, one JSON line each: every ardia call spends ~70 ms starting
# the CLI, while the app answers in ~5 ms.
zmodload zsh/net/socket
if ! zsocket ~/Library/Application\ Support/com.ardia.browser/ArdiaControl.sock 2>/dev/null; then
  echo "Ardia isn't running, or \"Let the ardia command control Ardia\" is off in Settings"
  exit 1
fi
ardia=$REPLY

request() {
  print -ru $ardia -- $1
  read -ru $ardia response
}

request '{"id":1,"method":"hello","params":{"caller":{"name":"Raycast"}}}'
request '{"id":2,"method":"workspace","params":{}}'

# Every window lists its own copy of the Top Apps, but a tab's live page moves
# to whichever window shows it, so the last focused window (the one Ardia
# brings forward when activated) comes first. A window's spaces follow the
# profile order.
tab=$(jq -r 'first(.result.windows | sort_by(.focused | not)[] | .spaces[].topApps[]
  | select(.url | startswith("https://app.slack.com/")) | .id)' <<<$response)

if [[ -z $tab ]]; then
  echo "No Slack tab in Ardia's Top Apps"
  exit 1
fi

# Activating switches the window to the tab's profile, but never focuses it.
request '{"id":3,"method":"apply","params":{"ops":[{"op":"tab.activate","tab":"'$tab'"}]}}'
if ! jq -e .result.ok >/dev/null <<<$response; then
  jq -r '(.error // .result.error).message' <<<$response
  exit 1
fi

open -b com.ardia.browser
