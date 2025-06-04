#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Zalo
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Zen Tabs
# @raycast.icon images/zalo-logo.png

# Documentation:
# @raycast.author Hareki

open -a "Zen"

osascript <<'APPLESCRIPT'
-- wait until Zen is frontmost
repeat until (application "Zen" is frontmost)
    delay 0.1
end repeat

tell application "System Events"
    keystroke "7" using command down
end tell
APPLESCRIPT

