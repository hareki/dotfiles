# AGENTS.md

## Overview

Personal Neovim 0.12+ configuration using the lazy.nvim plugin manager. `GLOSSARY.md` defines the terms this file, the skills and the code use.

`CLAUDE.md` is a symlink to this file: edit `AGENTS.md`, through anchored replacements against a fresh read. Keep every line under 1000 characters, since some views of this file trim longer lines, and a trimmed copy written back once deleted a rule.

The rules for one kind of change are project skills in `.agents/skills/` (`.claude/skills` links there); edit them under the same rule.

## LuaLS Diagnostics

The LuaLS diagnostics surfaced to you come from the `nvim-lua-lsp@dotfiles` plugin, which gives the server LuaJIT, Neovim's runtime and the lazy plugin dir, so its reports are real, except in scratch files outside the repo, where it flags the globals from `config/globals.lua` as undefined. When it flags `vim` itself as an undefined global, the session runs the official `lua-lsp` instead (started outside the dotfiles), and its `undefined-global`, `undefined-doc-name` and `undefined-field` reports on `vim` or plugin names and types are **false positives**: ignore them.

## Code Style

- **LuaLS annotations**: public APIs carry `--- @class`, `--- @param`, `--- @return` and `--- @alias`. A module's `@class` name is its `require` path, verbatim (`features/search/snacks-nvim/sources/tabs.lua` => `features.search.snacks-nvim.sources.tabs`), with aliases nested under it (`utils.notifier.Message`); renaming a module renames its class and every annotation that names it
- **Requires**: always assign to a local before use: `local x = require('y')` then `x.method()`, never `require('y').method()`
- **String formatting**: use `string.format(...)`, never the method form `('...'):format(...)`
- **Constants**: a file-level local holding data the file never reassigns or mutates once loaded (lookup tables, lists, config tables, fixed strings and numbers, a spec's desc `PREFIX`) is `UPPER_SNAKE` (`IGNORED_FILETYPES`, `TIMEOUT_MS`); state, requires and proxies, aliases (`local fs = vim.fs`), functions, handles (namespace and augroup ids) and objects (a ringbuf, a scoped notifier) stay `snake_case`
- **Helpers**: `config/globals.lua` puts `Defer`, `Notifier`, `Conf` and `UI` in every module's scope, and snacks.nvim sets `Snacks`. Look for a helper in `utils/ui/` (the `UI` global) and `utils/` before writing one
- **Defer proxies** (`Defer.on_index`, `Defer.on_exported_call`, `utils/lazy-require.lua`): every proxy, from `Defer` or from `utils.lazy-require` itself, carries `--- @module '<path>'` on the line above it: otherwise LuaLS sees a plain table, and a misspelled field passes the check to fail on the keypress
- **Notifications**: every notification goes through `Notifier` and names its source, which the notification history lists: `local notify = Notifier.scoped('Title')` in a module that notifies twice or more, `{ title = 'Title' }` on a one-off (an untitled one shows as "Notifier")
- **Nerd Font glyphs**: change a file that holds them (`config/icons.lua` among them) through anchored replacements, never a full rewrite, which has silently dropped private-use glyphs; a glyph can display as an empty string, so check one with `xxd` before treating it as empty
- **File/dir names**: all file and directory names use `kebab-case` and stay dot-free, since Lua `require` treats a literal `.` as a path separator. Names a tool requires keep their exact form (`lazy-lock.json`, `blink-cmp/snippets/package.json`, LSP server files named by server id such as `lsp/lua_ls.lua`)
- **Comment spacing**: a space after the comment marker: `-- x` not `--x`, `--- @param` not `---@param`
- **Augroups**: the owning plugin's or helper module's namespace (its `@class` name, as in **LuaLS annotations**) plus a `kebab-case` purpose (`chrome.lualine-nvim.buffer-status-cache` from `chrome/lualine-nvim/components/buffer-status.lua`, `features.git.git-conflict-nvim.conflicted-buffers`); config-level autocmds use `config.autocmds.<purpose>`. For dynamic suffixes, concatenate after a hyphen: `'utils.popup.link-' .. win`
- **Entry points**: a module that something outside nvim reaches by its path, a function name or a value carries an `Entry point:` comment in its header, naming the caller and the rule that follows (a stable path and names, or no globals and no config modules under `nvim --clean`); `rg 'Entry point:' lua` lists them. `tests/entry-points.lua` checks every caller except lazygit's diff renderer, and a new entry point or caller gets its check there. The diff renderer also puts `after/` on its runtimepath, so `after/` files follow its rule

## Commands

- **Format**: run `stylua .` after editing Lua
- **Test**: every headless nvim boot goes through `tests/run.sh`, `tests/probe.sh` or `tests/ab.sh`, which apply the rules in `tests/lib/env.sh`, each of which cost a real incident: never override `XDG_DATA_HOME`, never dump the environment, and end a boot with `os.exit`
