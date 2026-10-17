#!/usr/bin/osascript

# @raycast.schemaVersion 1
# @raycast.title Toggle Sleep Prevention
# @raycast.mode silent
# @raycast.packageName Amphetamine
# @raycast.icon ☕️

tell application id "com.if.Amphetamine"
	if session is active then
		end session
		return "Sleep prevention off"
	end if

	# Without options, the session takes its duration and display sleep setting from Amphetamine's Preferences.
	start new session
	return "Sleep prevention on"
end tell
