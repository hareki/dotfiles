# My Personal Rex Config

Rex config built around one key scheme shared with nvim, zsh and Claude Code, and app settings kept in the dotfiles instead of the Settings window.

## Requirements

### System

- **[Rex](https://www.superlogical.com/rex)**: the app and its `rex` CLI, which reads `~/.config/rex/init.lua` (this directory, stowed by the `rex` package)
- **[Maple Mono NF](https://github.com/subframe7536/maple-font)**: the terminal font `config/settings.lua` sets
- **[StyLua](https://github.com/JohnnyMorganz/StyLua)**: formatter, through the `.stylua.toml` symlinked from the nvim config
- **Remote Control** (Settings > General > Client Info): lets `rex` from a shell run client actions, which the Apply Settings action queues

### Companion configs

- **nvim** (`nvim/.config/nvim`): listens for the alt keys and escape sequences `features/program-keys.lua` sends, and hands pane navigation back to Rex at its edge (`features/navigation/window-navigation/`)
- **zsh** (`zsh/.config/zsh/keymaps.zsh`): atuin search on `alt+f`, completion on `alt+space`, forward-word on `ctrl+shift+y`

## Core Ideas

- `init.lua` only requires modules: `config/` holds Rex's own keymaps and the settings record, and each `features/<name>.lua` adds one custom action with the keys that run it
- **cmd => alt**: zsh gets no bytes for a cmd key and nvim's terminal drops the modifier, so most cmd keys send the alt key the program in the pane listens for
- **cmd+m/n/e/i** moves between panes, and inside nvim between its windows, as one grid (the Colemak-DH home row)
- **cmd+d** is the prefix for pane, tab and session management
- App settings live in macOS preferences, so `config/settings.lua` records them and the Apply Settings action writes them back

## Architecture

### Config (`config/`)

- `keymaps.lua`: bindings to Rex's built-in actions (palette, tabs, splits, zoom, copy mode, find, config reload)
- `settings.lua`: the settings record, one `{ '<name>', value }` pair per `client.setting.<name>` action, grouped as the Settings window groups them

### Features (`features/`)

- `program-keys.lua`: the cmd => alt keys, plus `send_text`, which writes raw escape sequences for the keys `pane.send_key` cannot encode
- `pane-navigation.lua`: `navigate`, which forwards the move to nvim, vim or fzf when one runs in the pane and moves Rex's focus otherwise
- `close-pane.lua`: `close_pane` on `cmd+d>x`, which closes a tab's last pane too, and the tab with it
- `apply-settings.lua`: `apply_settings`, which imports the theme file and sets every entry of `config/settings.lua`

### Themes (`themes/`)

- `Catppuccin Mocha`: a Ghostty theme file, imported by name on every apply (nvim opens it with the `ghostty` filetype)

## Code Style

- stylua: 100-char lines, 2-space indent, single quotes
- Action titles in CMOS 18 title case, as nvim's keymap descs
- A comment beside each sent key names the program and what it does there

## Tests

- `rex config check`: loads `init.lua` and counts its bindings and actions
- `rex keymap`: lists the config's bindings, without the app's defaults
- `rex do init.lua --action <name> -s <session> -b <block> key=value`: runs a custom action from the working file before any reload
