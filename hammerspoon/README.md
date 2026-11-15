# Hammerspoon

[Hammerspoon](https://www.hammerspoon.org) config, stowed to `~/.hammerspoon`.

## Setup

1. `brew install --cask hammerspoon`
2. `sync-dots hammerspoon`
3. Open Hammerspoon and allow it under System Settings > Privacy & Security > Accessibility: event taps and synthetic keystrokes need it.
4. In Hammerspoon's Preferences, check **Launch Hammerspoon at login**: the bindings only work while it runs.

## Gestures

Every gesture binding registers with `trackpad.on_gesture` instead of making its own event tap. Only the first read of a gesture event reports which fingers just landed or lifted, so `trackpad.lua` reads each event's touches once, before its type, and hands them to every handler registered for that type. A second gesture tap would see events first and hide those lifts from the shared one.

- **Two-finger double tap**: sends `Cmd+W`. It needs Trackpad > Scroll & Zoom > **Smart zoom** on, since that setting is macOS's two-finger double tap recognizer. The same recognizer holds back a two-finger tap's right click until no second tap follows, so the double tap never opens a context menu. Hammerspoon deletes the smart zoom event, so nothing zooms. An alert at config load says when the setting is off.
- **Three-finger double tap**: sends `Cmd+Shift+T`. macOS has no recognizer for it, so the config finds the taps in the raw trackpad touches: each one must stay under 0.3 seconds and barely move, and the pause between them is the system double-click interval. The limits sit at the top of `three-finger-double-tap.lua`. Keep Trackpad > Point & Click > **Look up & data detectors** off "Tap with three fingers", or each tap also looks up the word under the pointer.

## Tests

```bash
nvim --clean -l hammerspoon/tests/gestures.lua
```

It loads `init.lua` under a fake `hs` whose gesture events only report landings and lifts on their first read, and replays `tests/fixtures/taps.lua`, gesture events recorded off a real trackpad.
