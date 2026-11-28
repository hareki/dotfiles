<h1 align="center">hareki's Rex config</h1>

<hr>

<h4 align="center">
  <a href="#-getting-started">Install</a>
  ·
  <a href="#%EF%B8%8F-keybindings">Keybindings</a>
  ·
  <a href="#%EF%B8%8F-settings">Settings</a>
</h4>

<div align="center"><p>
    <a href="https://github.com/hareki/dotfiles/commits/main/rex">
      <img alt="Last commit" src="https://img.shields.io/github/last-commit/hareki/dotfiles?path=rex&style=for-the-badge&logo=starship&color=8bd5ca&logoColor=D9E0EE&labelColor=302D41" />
    </a>
    <a href="https://github.com/hareki/dotfiles/blob/main/LICENSE.md">
      <img alt="License" src="https://img.shields.io/github/license/hareki/dotfiles?style=for-the-badge&logo=starship&color=ee999f&logoColor=D9E0EE&labelColor=302D41" />
    </a>
</p></div>

A [Rex](https://www.superlogical.com/rex) config in Lua, for the one app that is both terminal
and multiplexer. Its <kbd>Cmd</kbd> keys send the keys Neovim, zsh and Claude Code bind, and its
settings live in the dotfiles instead of the Settings window.

## ✨ Features

- ⌨️ <kbd>Cmd</kbd> keys send the <kbd>Alt</kbd> key the program in the pane binds: zsh gets no bytes for a <kbd>Cmd</kbd> key, and Neovim's terminal drops the modifier
- 🪟 <kbd>Cmd-m</kbd>/<kbd>n</kbd>/<kbd>e</kbd>/<kbd>i</kbd> move across Rex panes and Neovim windows as one grid
- 🗂️ Prefix <kbd>Cmd-d</kbd> for splits, tabs, sessions and copy mode
- ⚙️ The app settings recorded in `config/settings.lua`, and one action that applies them all
- 🎨 Catppuccin Mocha, imported from a Ghostty theme file
- 🔁 Claude Code, Neovim and lazygit come back after a server restart: Claude Code through Rex's own rule, Neovim through `features/nvim-resume.lua`, which trusts the bare `nvim` Neovim reports so auto-session restores its session, and lazygit through `features/lazygit-resume.lua`, which trusts the bare `lazygit` the fork reports for the repo it is in
- 🔤 [Maple Mono NF](https://github.com/subframe7536/maple-font) a weight heavier in every style, SemiBold for regular text and ExtraBold for bold, as a family built from it

## 🤔 What is it?

- A personal config for one machine: macOS, with Neovim, zsh and Claude Code in the panes.

- `init.lua` only requires modules. `config/` holds the keys for Rex's own actions and the
  settings record, and each `features/<name>.lua` adds one feature, so deleting the file and its
  `init.lua` line removes the feature.

- Every <kbd>Cmd</kbd> key for a program sends the <kbd>Alt</kbd> key it binds, so the bindings
  live in the program that handles them: Neovim's keymaps, `zsh/.config/zsh/keymaps.zsh`.

## ⚡️ Requirements

- **[Rex](https://www.superlogical.com/rex)** on macOS, with its `rex` CLI
- **[Maple Mono NF](https://github.com/subframe7536/maple-font)**, the Nerd Font build the terminal font is made from, and **[uv](https://docs.astral.sh/uv/)** to run the script that makes it
- **[nvim](../nvim/) and [zsh](../zsh/) configs** from these dotfiles, which bind the keys Rex sends
- **Remote Control** (Settings > General > Client Info), to run Apply Settings from a shell: a client action from the CLI needs it

## 🚀 Getting Started

The config lives in my [dotfiles](https://github.com/hareki/dotfiles), which
[GNU Stow](https://www.gnu.org/software/stow/) links into `$HOME`.

<details><summary>Install with Stow</summary>

- Clone the dotfiles and link the `rex` package:

  ```sh
  git clone https://github.com/hareki/dotfiles ~/dotfiles
  stow -d ~/dotfiles -t ~ rex
  ```

- Build the terminal font, Maple Mono NF Rex, from the installed Maple Mono NF:

  ```sh
  ~/.config/rex/fonts/maple-mono-nf-rex.py
  ```

- Restart Rex, or run `rex config reload`.

- Run **Apply Settings from Dotfiles** from the command palette (<kbd>Cmd-p</kbd>). It imports
  the theme and sets the app settings.

</details>

## ⌨️ Keybindings

<kbd>Cmd-d</kbd> is the prefix for Rex's own pane, tab and session actions:

- **<kbd>prefix</kbd> <kbd>Shift-r</kbd>**: reload the config
- **<kbd>prefix</kbd> <kbd>-</kbd>** / **<kbd>prefix</kbd> <kbd>\\</kbd>**: split below / to the right
- **<kbd>prefix</kbd> <kbd>z</kbd>**: zoom the pane
- **<kbd>prefix</kbd> <kbd>x</kbd>**: close the pane, and the tab with its last pane. Rex's own <kbd>Cmd-w</kbd> closes the Neovim buffer here
- **<kbd>prefix</kbd> <kbd>n</kbd>** / **<kbd>prefix</kbd> <kbd>Shift-n</kbd>**: new tab / new session
- **<kbd>prefix</kbd> <kbd>r</kbd>**: rename the tab
- **<kbd>prefix</kbd> <kbd>Left</kbd>** / **<kbd>Right</kbd>**: move the tab left or right
- **<kbd>prefix</kbd> <kbd>Esc</kbd>**: copy mode
- **<kbd>prefix</kbd> <kbd>/</kbd>**: find in the pane. Rex's own <kbd>Cmd-f</kbd> opens atuin search here

Without the prefix:

- **<kbd>Cmd-p</kbd>**: the command palette
- **<kbd>Cmd-[</kbd>** / **<kbd>Cmd-]</kbd>**: previous / next tab
- **<kbd>Cmd-m</kbd>/<kbd>n</kbd>/<kbd>e</kbd>/<kbd>i</kbd>**: move left, down, up and right across Rex panes and Neovim windows

A pane running Neovim gets the move as <kbd>Alt-m</kbd>/<kbd>n</kbd>/<kbd>e</kbd>/<kbd>i</kbd>,
and Neovim hands it back with `rex focus` from a window at its edge
(`nvim/.config/nvim/lua/features/navigation/window-navigation/`). Any other pane moves Rex's focus
right away.

The <kbd>Cmd</kbd> keys for the program in the pane, each sent as its <kbd>Alt</kbd> key:

- **<kbd>Cmd-a</kbd>**: Claude Code in Neovim (claudecode.nvim)
- **<kbd>Cmd-g</kbd>**: lazygit in Neovim
- **<kbd>Cmd-t</kbd>**: Neovim's floating terminal
- **<kbd>Cmd-w</kbd>**: close the Neovim buffer
- **<kbd>Cmd-s</kbd>**: format and save in Neovim
- **<kbd>Cmd-r</kbd>**: reload the Neovim buffer
- **<kbd>Cmd-f</kbd>**: atuin history search in zsh
- **<kbd>Cmd-Space</kbd>**: completion in zsh, and blink.cmp's menu in Neovim (the AI items when it is already open)
- **<kbd>Shift-Enter</kbd>**: a new line in Claude Code, sent as <kbd>Alt-Enter</kbd>

Two go as the <kbd>Cmd</kbd> key itself, which Neovim reads through the kitty keyboard protocol:

- **<kbd>Cmd-Shift-s</kbd>**: format and save all, `<D-S-s>` in Neovim
- **<kbd>Cmd-Shift-w</kbd>**: close the other buffers, `<D-S-w>` in Neovim

The rest go as raw bytes, through the terminal's `write` method:

- **<kbd>Ctrl-m</kbd>**: toggle a multicursor.nvim cursor, <kbd>F37</kbd> in Neovim, which reads a bare <kbd>Ctrl-m</kbd> as Enter
- **<kbd>Ctrl-Shift-y</kbd>**: `forward-word` in zsh, which accepts the autosuggestion's next word

## ⚙️ Settings

Rex.app keeps its settings in its macOS preferences (`com.superlogical.rex`), where no file can
set them. `config/settings.lua` is their record: each `{ '<name>', value }` entry is a
`client.setting.<name>` action and the value it takes, grouped as the Settings window groups
them.

- **Apply Settings from Dotfiles** (`apply_settings`, in the command palette) imports the theme file and sets every entry. It reads `settings.lua` from disk on each run, so an edit applies without a config reload
- A setting changed in the Settings window lasts until the next apply, so change it in the record
- The import replaces the theme named after the file in place, so applying again is safe. `themes.dark.palette` names that theme: renaming the file means changing both
- Rex's [settings reference](https://www.superlogical.com/rex/docs/reference/mac-settings) gives each setting's name and values, and `defaults read com.superlogical.rex` shows the stored ones

## 📂 File Structure

<pre>
~/.config/rex
├── init.lua                 requires the keymaps, then each feature
├── config
│   ├── keymaps.lua          keys for Rex's own actions: palette, tabs, splits, copy mode, find
│   └── settings.lua         the settings record, one client.setting.* action per entry
├── features
│   ├── program-keys.lua     the Cmd => Alt keys, and the raw escape sequences
│   ├── pane-navigation.lua  navigate: hands the move to Neovim, or moves Rex's focus
│   ├── close-pane.lua       close_pane: closes a tab's last pane too, and the tab with it
│   ├── apply-settings.lua   apply_settings: imports the theme and sets every recorded setting
│   ├── nvim-resume.lua      the resume rule that starts Neovim again after a server restart
│   └── lazygit-resume.lua   the resume rule that starts lazygit again after a server restart
├── fonts
│   └── maple-mono-nf-rex.py builds the Maple Mono NF Rex family from the installed Maple Mono NF
└── themes
    └── Catppuccin Mocha     the Ghostty theme file Apply Settings imports
</pre>

## 🧪 Tests

Run them from `~/.config/rex`:

- **`rex config check`**: loads `init.lua` and counts its bindings and actions
- **`rex keymap`**: lists the config's bindings, without the app's defaults
- **`rex do init.lua --action <name> -s <session> -b <block> key=value`**: runs a custom action from the working file, before any reload. Point it at a probe session from `rex new Probe --json -- <cmd>`, never one in use
- **`stylua --check .`**: the formatting check, with the `.stylua.toml` symlinked from nvim's config

## 📚 Docs

The conventions for each kind of change live in [`docs/conventions/`](./.config/rex/docs/conventions/):

- **[code-style.md](./.config/rex/docs/conventions/code-style.md)**: requires, constants, sections, file names
- **[keys.md](./.config/rex/docs/conventions/keys.md)**: where a binding goes, the <kbd>Cmd</kbd> => <kbd>Alt</kbd> keys, raw bytes, shadowed defaults and pane navigation
- **[actions.md](./.config/rex/docs/conventions/actions.md)**: filing, naming and titling a custom action, and server versus client calls
- **[settings.md](./.config/rex/docs/conventions/settings.md)**: the settings record, the stored values and the theme import

[docs/testing.md](./.config/rex/docs/testing.md) covers the checks, the probe sessions live tests run in, and the actions that stay untested live.

- **[Rex docs](https://www.superlogical.com/rex/docs)**: the Lua API, the [default shortcuts](https://www.superlogical.com/rex/docs/reference/mac-actions) a config binding shadows, and the [settings](https://www.superlogical.com/rex/docs/reference/mac-settings)
