# AGENTS.md

## Overview

Personal config for Rex, the terminal multiplexer app (`TERM_PROGRAM=rex`). Stow links this directory to `~/.config/rex`, where Rex reads `init.lua`.

`CLAUDE.md` is a symlink to this file: edit `AGENTS.md`, through anchored replacements against a fresh read. Keep every line under 1000 characters, since some views of this file trim longer lines.

Rex's API ships no type definitions: `.luarc.json` declares only the `rex` global, so LuaLS checks none of its fields. Look an API up before using it: the `superlogical` MCP server (`search_docs`, `read_doc`), or `https://www.superlogical.com/rex/docs/llms-full.txt`. The app's default shortcuts are listed only in `reference/mac-actions.md`, and the settings in `reference/mac-settings.md`; `rex actions --json` lists the actions a client or the server offers.

## Code Style

- **Requires**: Rex's `package.path` is this directory alone, so modules sit at its root with no `lua/` dir (`require('config.settings')`). Assign a require to a local before use: `local settings = require('config.settings')`, never `require('config.settings')[1]`
- **String formatting**: use `string.format(...)`, never the method form `('...'):format(...)`
- **Constants**: a file-level local holding data the file never reassigns or mutates (lookup tables, lists, fixed strings) is `UPPER_SNAKE` (`TERMINAL`, `NAVIGATION_KEYS`, `THEME`); functions and requires stay `snake_case`
- **Actions**: `name` in `snake_case`, `title` in CMOS 18 title case as nvim's keymap descs (rule 8.160: prepositions of five or more letters capitalized, "Close Pane, or the Tab with Its Last Pane"), and a `description` when the title leaves out what the action does
- **Errors**: a server call returns `result, err`; raise a non-nil `err` with `error(err, 0)`, which shows Rex's message without a Lua file position
- **Sent keys**: every key a binding sends to the program in the pane carries a trailing comment naming the program and what the key does there (`'f', -- zsh: atuin search`), since nothing in this directory shows what reads it
- **Sections**: group a file's bindings or settings under `-- [[ Name ]]` headers
- **File names**: `kebab-case`, dot-free, since `require` reads a `.` as a path separator. The theme file keeps its exact name: Rex names the imported theme after it (see **Settings**)
- **Comment spacing**: a space after the comment marker: `-- x` not `--x`

## Commands

- **Format**: run `stylua .` after editing Lua (check only: `stylua --check .`). `.stylua.toml` is a symlink to nvim's
- **Check**: `rex config check` loads `init.lua` and counts its bindings and actions; `rex keymap` lists the bindings (`rex keymap --json | jq '.bindings[] | select(.keys[0] == "cmd+d")'`), and exits 1 on an error
- **Reload**: `rex config reload`, or `cmd+d>shift+r` in the app
- **Run an action**: `rex do init.lua --action <name> -s <session> -b <block> key=value` (JSON args: `--args '{"data":"..."}'`) runs a custom action from the working file, before any reload
- **Probe**: run every live test in a probe session, never the user's: `rex new Probe --json -- <cmd>` makes a session the app does not show, `rex split -s S -b B --focus=false --shell=none -- /bin/cat -v` adds a pane that prints the bytes it gets, `rex capture -s S -b B --trim` reads a pane, `rex session inspect S --json | jq '.windows[0].focused_block_id'` shows where focus went, and `rex kill S` removes the session

## Architecture

- `init.lua` only requires modules: `config.keymaps`, then one line per feature
- `config/keymaps.lua` binds Rex's built-in actions. A key that runs a custom action is bound in that action's feature file
- `features/<name>.lua` defines one custom action (`rex.action`) with the keys that run it; deleting the file and its `init.lua` line removes the feature
- `config/settings.lua` is the settings record (see **Settings**), `themes/` the Ghostty theme files Apply Settings imports

### Server and client calls

An action reaches Rex through server calls (`rex.call`, `rex.block.call`, `rex.session.*`) or client actions (`pane.send_key`, `pane.close`, `rex.client.queue`, every `client.*`). From the CLI, a client action needs Remote Control (Settings > General > Client Info), and it runs in the user's app. So build an action on server calls wherever one exists, which `rex do` can test against a probe session: `rex.block.call('com.superlogical.terminal', 'write' | 'process', ...)`, `rex.session.focus_direction`, `rex.call('block.close', ...)`.

Leave actions that queue `client.tab.close`, `client.close` or `client.setting.*` untested live: they go to the user's one app client even from `rex do`, and the auto-mode classifier refuses `client.setting.*` probes.

## Keys

- **cmd => alt**: a cmd key reaches only a program that turned on the kitty keyboard protocol (`\27[<codepoint>;9u`, `10` with shift, which nvim maps as `<D-s>`). zsh gets no bytes for it, nvim's `:terminal` drops the modifier and types the bare letter, and legacy `alt+shift+s` arrives as `\es`, shift lost. Alt is the one modifier that passes zsh, nvim's terminal, fzf and Claude Code, so a new cmd key for a program goes in `ALT_KEYS` (`features/program-keys.lua`) and the program listens for the alt key. Only `shift+cmd+s` and `shift+cmd+w` go as real cmd bytes, through `send_text`
- **Raw bytes**: `pane.send_key` encodes a key as the terminal would (`ctrl+shift+f1` reaches nvim as `<C-S-F1>`), while the same key written as bytes through `send_text` reaches it as another (`\27[1;6P` is `<F37>`). Pick the form that lands on the key the program maps, and say which in the comment
- **Shadowed defaults**: the app's default shortcuts (`cmd+f`, and menu key equivalents such as `cmd+w` and `shift+cmd+w`) are a layer `rex keymap` does not list, and a config binding shadows them. Check `reference/mac-actions.md` before binding a cmd key, and when a binding takes one over, move the default under the `cmd+d` prefix with a comment (`cmd+d>/` for find, `cmd+d>x` for close)
- **Pane navigation**: `cmd+m/n/e/i` is one grid across Rex panes and nvim windows. `navigate` writes `\27` plus the letter (alt+m/n/e/i) when the pane's foreground process is in `NAVIGATES_ITSELF` (`process` returns `.foreground.name`, `nvim` even through the mise shim's exec), and nvim calls `rex focus <direction> --session $REX_SESSION` from a window at its edge (`nvim/.config/nvim/lua/features/navigation/window-navigation/`). Change a direction key on both sides

## Settings

Rex.app keeps its settings in macOS preferences (`com.superlogical.rex`), which no file sets. `config/settings.lua` records them as `{ '<name>', value }` pairs, each the `client.setting.<name>` action and its `value`, and `apply_settings` sets them all. A setting changed in the Settings window is lost at the next apply, so a settings change is an edit to the record.

- Take a setting's name and its values from `reference/mac-settings.md` (`rex -C <client label> actions --json` gives each enum)
- Read the stored values with `defaults read com.superlogical.rex`, never the plist file, which lags by seconds. Their keys differ from the setting names: `interfaceStyle` holds style and tint together (classic + tint `useTheme`, classic `system`, glass + tint `blendTheme`, glass `modern`), `terminalPaddingColor` off/automatic/always is `background`/`extend`/`extend-always`, and border opacity and line height take percent
- `programActivitySoundVolume` stays out of the record: its scale against the action's `value` is unknown
- `client.theme.import` replaces the theme of the imported file's name in place, so `apply_settings` imports `themes/Catppuccin Mocha` on every run, and `themes.dark.palette` names it. Renaming the file renames the theme: change both

## Entry Points

Files outside this directory reach into it by path or by key, so change them together:

- `features/pane-navigation.lua` and nvim's `features/navigation/window-navigation/` (see **Pane navigation**)
- `features/program-keys.lua` and the programs that listen for its keys: nvim's keymaps, `zsh/.config/zsh/keymaps.zsh` (`^[f` atuin, `\e ` completion, `\e[1;6Y` forward-word), Claude Code (`alt+enter` new line)
- `features/apply-settings.lua` reads the theme at `~/.config/rex/themes/Catppuccin Mocha`, the stowed path, so it works only once stowed
- nvim's `config/filetypes/init.lua` opens `rex/themes/*` with the `ghostty` filetype
