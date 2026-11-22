<h1 align="center">hareki's Hammerspoon config</h1>

<hr>

<h4 align="center">
  <a href="#-getting-started">Install</a>
  ·
  <a href="#-gestures">Gestures</a>
  ·
  <a href="#-tests">Tests</a>
</h4>

<div align="center"><p>
    <a href="https://github.com/hareki/dotfiles/commits/main/hammerspoon">
      <img alt="Last commit" src="https://img.shields.io/github/last-commit/hareki/dotfiles?path=hammerspoon&style=for-the-badge&logo=starship&color=8bd5ca&logoColor=D9E0EE&labelColor=302D41" />
    </a>
    <a href="https://github.com/hareki/dotfiles/blob/main/LICENSE.md">
      <img alt="License" src="https://img.shields.io/github/license/hareki/dotfiles?style=for-the-badge&logo=starship&color=ee999f&logoColor=D9E0EE&labelColor=302D41" />
    </a>
</p></div>

A [Hammerspoon](https://www.hammerspoon.org) config, stowed to `~/.hammerspoon`, that turns
trackpad double taps into <kbd>Cmd-W</kbd> and <kbd>Cmd-Shift-T</kbd>.

## ✨ Features

- 👆 A two-finger double tap sends <kbd>Cmd-W</kbd>
- 🖐️ A three-finger double tap sends <kbd>Cmd-Shift-T</kbd>
- 🔁 One shared gesture event tap that every binding registers with
- 🧪 Tests that replay gesture events recorded off a real trackpad

## 🤔 What is it?

- A personal config for one machine, with the macOS trackpad settings below.

- `init.lua` only loads the gestures. Each gesture is one file under `gestures/`, and
  `gestures/trackpad.lua` owns the one event tap they all share.

## ⚡️ Requirements

- **macOS** with a trackpad
- **[Hammerspoon](https://www.hammerspoon.org)**, with Accessibility access
- **Trackpad > Scroll & Zoom > Smart zoom** on, for the two-finger double tap
- **Trackpad > Point & Click > Look up & data detectors** off "Tap with three fingers", for the three-finger one

## 🚀 Getting Started

The config lives in my [dotfiles](https://github.com/hareki/dotfiles), which
[GNU Stow](https://www.gnu.org/software/stow/) links into `$HOME`.

<details><summary>Install with Stow</summary>

- Install Hammerspoon:

  ```sh
  brew install --cask hammerspoon
  ```

- Link the `hammerspoon` package:

  ```sh
  sync-dots hammerspoon
  ```

- Open Hammerspoon and allow it under System Settings > Privacy & Security > Accessibility: event taps and synthetic keystrokes need it.

- In Hammerspoon's Preferences, check **Launch Hammerspoon at login**: the bindings only work while it runs.

</details>

## 👆 Gestures

Every gesture binding registers with `trackpad.on_gesture` instead of making its own event tap. Only the first read of a gesture event reports which fingers just landed or lifted, so `gestures/trackpad.lua` reads each event's touches once, before its type, and hands them to every handler registered for that type. A second gesture tap would see events first and hide those lifts from the shared one.

- **Two-finger double tap**: sends `Cmd+W`. It needs Trackpad > Scroll & Zoom > **Smart zoom** on, since that setting is macOS's two-finger double tap recognizer. The same recognizer holds back a two-finger tap's right click until no second tap follows, so the double tap never opens a context menu. Hammerspoon deletes the smart zoom event, so nothing zooms. An alert at config load says when the setting is off.
- **Three-finger double tap**: sends `Cmd+Shift+T`. macOS has no recognizer for it, so the config finds the taps in the raw trackpad touches: each one must stay under 0.3 seconds and barely move, and the pause between them is the system double-click interval. The limits sit at the top of `gestures/three-finger-double-tap.lua`. Keep Trackpad > Point & Click > **Look up & data detectors** off "Tap with three fingers", or each tap also looks up the word under the pointer.

## 📂 File Structure

<pre>
~/.hammerspoon
├── init.lua                      loads the gestures
└── gestures
    ├── trackpad.lua              the shared event tap and trackpad.on_gesture
    ├── two-finger-double-tap.lua Cmd+W on smart zoom's double tap
    └── three-finger-double-tap.lua
                                  Cmd+Shift+T from the raw touches, and its limits
</pre>

## 🧪 Tests

```bash
nvim --clean -l hammerspoon/tests/gestures.lua
```

It loads `init.lua` under a fake `hs` whose gesture events only report landings and lifts on their first read, and replays `tests/fixtures/taps.lua`, gesture events recorded off a real trackpad.
