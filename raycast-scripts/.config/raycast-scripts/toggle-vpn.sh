#!/usr/bin/env -S LC_ALL=en_US.UTF-8 bash

# @raycast.schemaVersion 1
# @raycast.title Toggle VPN
# @raycast.mode silent
# @raycast.packageName Cloudflare WARP
# @raycast.icon 🌐

# LC_ALL is pinned in the shebang for the same reason as in
# cycle-audio-output.sh.

set -e

export PATH="/usr/local/bin:$PATH"

app_id=com.cloudflare.1dot1dot1dot1.macos

# The connect switch decides rather than the connection status, so a tunnel
# stuck connecting still toggles off.
if [[ $(warp-cli settings) == *"Always On: true"* ]]; then
  warp-cli disconnect >/dev/null
  # The root daemon behind warp-cli keeps running (stopping it needs root), so
  # quitting the GUI is what takes WARP out of the menu bar. WARP answers the
  # quit Apple Event with -128 (User canceled) and then quits anyway, and a
  # quit sent to a WARP that isn't running is a no-op.
  if ! error=$(osascript -e 'try' -e "tell application id \"$app_id\" to quit" \
    -e 'on error number -128' -e 'end try' 2>&1 >/dev/null); then
    # The tunnel is already down, so the failure toast has to say so. Raycast
    # titles it with the last line of the output, which puts stderr after
    # stdout, so osascript's error goes into that line instead of stderr.
    echo "VPN off, but WARP didn't quit: ${error#*execution error: }"
    exit 1
  fi
  echo "VPN off"
else
  warp-cli connect >/dev/null
  # Reopening a running WARP shows its window, and a fresh launch restores the
  # window's visibility from its last quit, so reset that first. `open -j`
  # would hide the window too, but it keeps the Flutter engine, and with it
  # the menu bar icon, from starting.
  if ! pgrep -xq -U "$UID" "Cloudflare WARP"; then
    defaults write "$app_id" flutter.warp_app_window_was_visible -bool false
    open -g -b "$app_id"
  fi
  echo "VPN on"
fi
