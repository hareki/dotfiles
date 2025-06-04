#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Search Zen Tabs
# @raycast.mode silent

# Optional parameters:
# @raycast.packageName Zen
# @raycast.icon images/zen-logo.png

# Documentation:
# @raycast.author Hareki

open -a "Zen"

osascript <<'APPLESCRIPT'
-- wait until Zen is frontmost
repeat until (application "Zen" is frontmost)
    delay 0.1
end repeat

tell application "System Events"
    keystroke "l" using command down   -- ⌘ L (focus address bar)
    key code 51                        -- Delete / Backspace
    keystroke "% "                     -- % followed by space
end tell
APPLESCRIPT

