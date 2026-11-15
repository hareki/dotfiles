# Hammerspoon

[Hammerspoon](https://www.hammerspoon.org) config, stowed to `~/.hammerspoon`.

## Setup

1. `brew install --cask hammerspoon`
2. `sync-dots hammerspoon`
3. Open Hammerspoon and allow it under System Settings > Privacy & Security > Accessibility: event taps and synthetic keystrokes need it.
4. In Hammerspoon's Preferences, check **Launch Hammerspoon at login**: the bindings only work while it runs.

## Gestures

- **Two-finger double tap**: sends `Cmd+W`. It needs Trackpad > Scroll & Zoom > **Smart zoom** on, since that setting is macOS's two-finger double tap recognizer. The same recognizer holds back a two-finger tap's right click until no second tap follows, so the double tap never opens a context menu. Hammerspoon deletes the smart zoom event, so nothing zooms. An alert at config load says when the setting is off.
