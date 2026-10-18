#!/usr/bin/osascript

# @raycast.schemaVersion 1
# @raycast.title Toggle Sleep Prevention
# @raycast.mode silent
# @raycast.packageName Amphetamine
# @raycast.icon ☕️

# A cold launch by the `tell` below starts Amphetamine's own session (Preferences => Start Session At Launch) before the
# first query is answered, so only a session in an already running Amphetamine counts as on.
set wasRunning to running of application id "com.if.Amphetamine"

tell application id "com.if.Amphetamine"
	set sessionActive to session is active
	if not (wasRunning and sessionActive) then
		# Without options, the session takes its duration and display sleep setting from Amphetamine's Preferences.
		if not sessionActive then start new session
		return "Sleep prevention on"
	end if

	end session
end tell

# Amphetamine silently ignores quit Apple Events (its sdef maps the application class to a missing NLApplication
# class), so SIGTERM it once `end session` has run its own teardown.
do shell script "pkill -x Amphetamine"
return "Sleep prevention off"
