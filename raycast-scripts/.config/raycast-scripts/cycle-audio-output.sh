#!/usr/bin/env -S LC_ALL=en_US.UTF-8 bash

# @raycast.schemaVersion 1
# @raycast.title Cycle Audio Output
# @raycast.mode silent
# @raycast.packageName Audio
# @raycast.icon 🔈

# Raycast launches scripts with LC_ALL set to an ICU-style tag (e.g.
# "en-VN-u-ca-gregory") that libc doesn't recognize. bash 5 complains about
# it at startup, before the script body runs, so the override has to live in
# the shebang rather than in an `export` below.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Devices to cycle through, in order. Names must match
# `SwitchAudioSource -a -t output` exactly. Add more here later.
outputs=("MacBook Pro Speakers" "Redmi 电脑音箱" "PRO X" "KT USB Audio")

# Friendly names shown in the HUD.
display_name() {
  case "$1" in
    "MacBook Pro Speakers") echo "MacBook Speakers" ;;
    "Redmi 电脑音箱") echo "Redmi Speaker" ;;
    "PRO X") echo "Logitech G Pro X" ;;
    "KT USB Audio") echo "Castor Pro" ;;
    *) echo "$1" ;;
  esac
}

# Snapshot of currently available output devices.
available=$(SwitchAudioSource -a -t output)
is_available() {
  grep -qxF "$1" <<< "$available"
}

current=$(SwitchAudioSource -c)

# Find the current device's position, then walk forward to the next
# available device in the cycle. Skips anything not plugged in.
start=-1
for i in "${!outputs[@]}"; do
  if [[ "${outputs[$i]}" == "$current" ]]; then
    start=$i
    break
  fi
done

next=""
count=${#outputs[@]}
for ((step = 1; step <= count; step++)); do
  candidate="${outputs[$(( (start + step) % count ))]}"
  if is_available "$candidate"; then
    next="$candidate"
    break
  fi
done

if [[ -z "$next" ]]; then
  echo "No available output device to switch to"
  exit 1
fi

SwitchAudioSource -s "$next" >/dev/null
echo "Switched to $(display_name "$next")"
