# AGENTS.md

## Overview

Personal Neovim 0.12+ configuration using the lazy.nvim plugin manager. Plugin specs sit in three tiers under `lua/` (`core/`, `chrome/`, `features/{domain}/`); `GLOSSARY.md` defines the terms this file and the code use.

`CLAUDE.md` is a symlink to this file: edit `AGENTS.md`, through anchored replacements against a fresh read. Keep every line under 1000 characters, since some views of this file trim longer lines, and a trimmed copy written back once deleted a rule.

The rules for one kind of change (plugin specs, keymaps, UI, language servers, forks, testing) are project skills in `.agents/skills/`, which `.claude/skills` links to; edit them there, under the same rule.

## LuaLS Diagnostics

The LuaLS diagnostics surfaced to you come from Claude Code's server, run by the `nvim-lua-lsp@dotfiles` plugin (`.claude/marketplace/.claude-plugin/marketplace.json`), which this project's and the dotfiles root's `.claude/settings.json` enable in place of the official `lua-lsp`. Its `settings` give it LuaJIT, Neovim's runtime and the lazy plugin dir wherever it roots, so its reports are real, except in scratch files outside the repo, where it flags the globals from `config/globals.lua` as undefined. When it flags `vim` itself as an undefined global, the session runs the official `lua-lsp` instead (started outside the dotfiles), and its `undefined-global`, `undefined-doc-name` and `undefined-field` reports on `vim` or plugin names and types are **false positives**: ignore them.

## Code Style

- **LuaLS annotations**: `--- @class`, `--- @param`, `--- @return`, `--- @alias` for public APIs
- **LuaLS class names**: a module's `@class` name is its `require` path, verbatim (`config/builtin-keymaps.lua` => `config.builtin-keymaps`, `features/search/snacks-nvim/sources/tabs.lua` => `features.search.snacks-nvim.sources.tabs`, `utils/ui/statusline.lua` => `utils.ui.statusline`), with aliases nested under it (`utils.notifier.Message`); renaming a module renames its class and every `require()` path and annotation that names it
- **Requires**: always assign to a local before use: `local x = require('y')` then `x.method()`, never `require('y').method()`
- **String formatting**: use `string.format(...)`, never the method form `('...'):format(...)`
- **Constants**: a file-level local holding data the file never reassigns or mutates once loaded (lookup tables, lists, config tables, fixed strings and numbers, a spec's desc `PREFIX`) is `UPPER_SNAKE` (`IGNORED_FILETYPES`, `TIMEOUT_MS`); state, requires and proxies, aliases (`local fs = vim.fs`), functions, handles (namespace and augroup ids) and objects (a ringbuf, a scoped notifier) stay `snake_case`
- **Helpers**: `config/globals.lua` puts `Defer`, `Notifier`, `Conf` and `UI` in every module's scope, and snacks.nvim sets `Snacks`. Look for a helper in `utils/ui/` (the `UI` global) and `utils/` before writing one
- **Defer proxies** (`Defer.on_index`, `Defer.on_exported_call`, `utils/lazy-require.lua`): every proxy, from `Defer` or from `utils.lazy-require` itself, carries `--- @module '<path>'` on the line above it: otherwise LuaLS sees a plain table, and a misspelled field passes the check to fail on the keypress
- **Notifications**: every notification goes through `Notifier` and names its source, which the notification history lists: `local notify = Notifier.scoped('Title')` in a module that notifies twice or more, `{ title = 'Title' }` on a one-off (an untitled one shows as "Notifier")
- **Nerd Font glyphs**: change a file that holds them (`config/icons.lua` among them) through anchored replacements, never a full rewrite, which has silently dropped private-use glyphs; a glyph can display as an empty string, so check one with `xxd` before treating it as empty
- **File/dir names**: all file and directory names use `kebab-case` and stay dot-free, since Lua `require` treats a literal `.` as a path separator. Names a tool requires keep their exact form (`lazy-lock.json`, `blink-cmp/snippets/package.json`, LSP server files named by server id such as `lsp/lua_ls.lua`)
- **Comment spacing**: a space after the comment marker: `-- x` not `--x`, `--- @param` not `---@param` (leave `--` inside string literals and `--[[` block markers alone).
- **Augroups**: the owning plugin's or helper module's namespace (as in **LuaLS class names**) plus a `kebab-case` purpose (`chrome.lualine-nvim.buffer-status-cache` from `chrome/lualine-nvim/components/buffer-status.lua`, `features.git.git-conflict-nvim.conflicted-buffers`, `core.lsp.nvim-lspconfig.utils.typescript.attach-vtsls` from `nvim-lspconfig/utils/typescript.lua`); config-level autocmds use `config.autocmds.<purpose>`. For dynamic suffixes, concatenate after a hyphen: `'utils.popup.link-' .. win`
- **Entry points**: something outside nvim (lazygit and its diff renderer, the `tsave` zsh function, Claude Code's Stop hook, the tools that set `NVIM_INTEGRATION`) reaches a module by its path, a function name or a value. That module carries an `Entry point:` comment naming the caller and the rule that follows (a stable path and names, or no globals and no config modules under `nvim --clean`); `rg 'Entry point:' lua` lists them, and `tests/entry-points.lua` checks the callers. A new entry point says the same in its header. lazygit's diff renderer also puts `after/` on its runtimepath, so `after/` files follow its rule

## Commands

- **Format**: run `stylua .` after editing Lua (check only: `stylua --check .`; config in `.stylua.toml`), installed via Homebrew, on `$PATH`
- **Test**: every headless nvim boot goes through `tests/run.sh` (the test files), `tests/probe.sh` (a one-off Lua payload) or `tests/ab.sh` (the diff of what two revisions define), which apply the rules in `tests/lib/env.sh`, each of which cost a real incident: never override `XDG_DATA_HOME`, never dump the environment, and end a boot with `os.exit`
- No build system
