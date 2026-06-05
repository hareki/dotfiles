#!/usr/bin/env bash

# @raycast.schemaVersion 1
# @raycast.title Cycle Audio Output
# @raycast.mode silent
# @raycast.packageName Audio
# @raycast.icon 🔈

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Devices to cycle through, in order. Names must match
# `SwitchAudioSource -a -t output` exactly. Add more here later.
outputs=("PRO X" "Redmi 电脑音箱")

# Friendly names shown in the HUD.
display_name() {
  case "$1" in
    "PRO X") echo "Logitech G Pro X" ;;
    "Redmi 电脑音箱") echo "Redmi Speaker" ;;
    *) echo "$1" ;;
  esac
}

current=$(SwitchAudioSource -c)

# Default to the first device (covers the case where the current
# output is not in the cycle list, e.g. speakers or monitor).
next="${outputs[0]}"

for i in "${!outputs[@]}"; do
  if [[ "${outputs[$i]}" == "$current" ]]; then
    next="${outputs[$(( (i + 1) % ${#outputs[@]} ))]}"
    break
  fi
done

SwitchAudioSource -s "$next" >/dev/null
echo "Switched to $(display_name "$next")"
