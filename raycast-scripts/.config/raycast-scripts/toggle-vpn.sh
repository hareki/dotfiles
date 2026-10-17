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

# The connect switch decides rather than the connection status, so a tunnel
# stuck connecting still toggles off.
if [[ $(warp-cli settings) == *"Always On: true"* ]]; then
  warp-cli disconnect >/dev/null
  echo "VPN off"
else
  warp-cli connect >/dev/null
  echo "VPN on"
fi
