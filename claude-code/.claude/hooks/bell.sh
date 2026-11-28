#!/bin/bash
# nvim's terminal drops the bell, and a native notification needs terminal-notifier or alerter,
# which can't show the terminal's icon without blocking stdio

# This is only choice left, a simple sound play
# Claude needs to execute this, so it can't be a zsh function
# Accepts an optional sound name from /System/Library/Sounds, defaulting to Glass
# Backgrounded: Claude holds the turn open (spinner up, new prompts queued) until
# the hook exits, then up to ~0.5s more while inherited output pipes stay open
afplay "/System/Library/Sounds/${1:-Glass}.aiff" >/dev/null 2>&1 &
