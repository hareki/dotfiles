#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Cycle Audio Output
# @raycast.mode silent
# @raycast.packageName Audio
# @raycast.icon 🔈

export PATH="/opt/homebrew/bin:$PATH"

# Devices to cycle through, in order, as "device|friendly name shown in the
# HUD" (a bare "device" shows as is). Device names must match
# `SwitchAudioSource -a -t output` exactly. Add more here later.
outputs=(
  "MacBook Pro Speakers|MacBook Speakers"
  "Redmi 电脑音箱|Redmi Speaker"
  "PRO X|Logitech G Pro X"
  "KT USB Audio|Castor Pro"
)

current=$(SwitchAudioSource -c)

# Find the current device's position, then walk forward to the next
# available device in the cycle. Skips anything not plugged in, which
# `SwitchAudioSource -s` refuses with a non-zero exit.
start=-1
for i in "${!outputs[@]}"; do
  if [[ "${outputs[$i]%%|*}" == "$current" ]]; then
    start=$i
    break
  fi
done

for candidate in "${outputs[@]:start+1}" "${outputs[@]:0:start+1}"; do
  if SwitchAudioSource -s "${candidate%%|*}" >/dev/null; then
    echo "Switched to ${candidate#*|}"
    exit 0
  fi
done

echo "No available output device to switch to"
exit 1
