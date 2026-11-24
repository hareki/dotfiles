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

Gesture bindings register with `trackpad.on_gesture` in `gestures/trackpad.lua` rather than making their own event tap. A second tap would hide finger lifts from the shared one.

- **Two-finger double tap**: sends `Cmd+W`. Needs Trackpad > Scroll & Zoom > **Smart zoom** on, which is macOS's recognizer for the gesture. Nothing zooms and no context menu opens. An alert at config load says when the setting is off.
- **Three-finger double tap**: sends `Cmd+Shift+T`. The timing limits are at the top of `gestures/three-finger-double-tap.lua`. Keep Trackpad > Point & Click > **Look up & data detectors** off "Tap with three fingers", or each tap also looks up the word under the pointer.

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
