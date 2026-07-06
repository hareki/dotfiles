# AGENTS.md

This file provides guidance to AI coding agents (e.g. Claude Code) when working with code in this repository.

## Overview

Personal Neovim configuration using **lazy.nvim** plugin manager. Targets Neovim 0.12+ with native LSP support.

## LuaLS Diagnostics Caveat

The LuaLS diagnostics surfaced to you will often report `undefined-global` for the project globals documented in the [Globals](#globals-luaconfigglobalslua) table, as well as for plugin-provided globals (e.g. `Snacks`). **[VERY IMPORTANT] These are false positives, ignore these warnings entirely.**

## Code Style

- **Formatter**: stylua — 100-char lines, 2-space indent, single quotes (see `.stylua.toml`)
- **LuaLS annotations**: `--- @class`, `--- @param`, `--- @return`, `--- @alias` for public APIs
- **Requires**: always assign to a local before use — `local x = require('y')` then `x.method()`, never `require('y').method()`
- **Keymaps**: always use `vim.keymap.set()` with `<cmd>...<cr>` strings — never structured `vim.cmd` API. Fall back to function callbacks only when runtime values or multi-statement logic are needed. Always include `desc` in CMOS 18 title case ("Find Files", "Go to Definition")
- **Icons**: always import from `config/icons.lua` via the `Conf.icons` global — never hardcode icon strings
- **File/dir names**: all file and directory names use `kebab-case`. Name a plugin's spec file/dir after its GitHub repo name (the part after `/`), with **every `.` replaced by `-`**, applied identically to single-file specs and directories (`noice.nvim` → `noice-nvim.lua`, `telescope.nvim` → `telescope-nvim/`, `mini.ai` → `mini-ai/`, `copilot.lua` → `copilot-lua.lua`, `nvim-tree.lua` → `nvim-tree-lua/`). User service/helper modules (under `lua/services/`, `lua/utils/`, etc.) are **also `kebab-case`** (`services/statusline.lua`, `utils/lazy-require.lua`, `utils/project-config.lua`, `services/keymap-registry.lua`, `utils/style-enforcers/`); multi-word names use hyphens, never underscores. Every name stays dot-free because Lua `require` treats a literal `.` as a path separator; hyphens are valid in both `require()` strings and LuaLS `@class`/`@field`/`@type` names, so when renaming a module update its `require()` paths and those annotations together. **Keep the exact name** for 3rd-party-required files (`lazy-lock.json`, `snippets/package.json`) and for LSP server config files whose basename must equal the server id (`core/lsp/nvim-lspconfig/lsp/lua_ls.lua`, `typos_lsp.lua`). Local Lua variable/function identifiers keep their `snake_case` (they are not filenames); augroup name string literals use `kebab-case` per the **Augroups** convention below.
- **Comment spacing**: always put a space between the comment marker and content — `-- x` not `--x`, `--- @param` not `---@param`. Applies to both inline comments (`--`) and LuaLS annotations (`---`). Never touch `--` inside string literals or `--[[` block markers.
- **Augroups**: `vim.api.nvim_create_augroup` names use a dotted module-path prefix with `kebab-case` segments — `<tier-or-domain>.<plugin>.<purpose>`. Core/chrome plugins use the tier (`core.snacks.hover-image`, `chrome.lualine.buffer-status-cache`); features plugins use the domain name directly, dropping the `features.` prefix (`git.git-conflict.keymaps`, `navigation.nvim-tree.preview`); helpers under `lua/utils/` use the `utils.` prefix (`utils.hl-at-cursor.popup-<win>`); config-level autocmds use the `config.autocmds.` prefix (`config.autocmds.checktime`). For dynamic suffixes, concatenate after a hyphen: `'utils.hl-at-cursor.popup-' .. win`

## Commands

- **Format**: `stylua .` (check only: `stylua --check .`) — installed via mise-en-place, on `$PATH`
- No test suite or build system — this is a personal Neovim config, not a library

## Architecture

### Boot Order (`init.lua`)

`vim.loader.enable` → `config.globals` → `config.options` → `config.autocmds` → `config.usercmds` → `config.keymaps` → `config.lazy`

### Plugin Tiers (`lua/`)

| Directory            | Purpose                                                                                               | Load behavior                          |
| -------------------- | ----------------------------------------------------------------------------------------------------- | -------------------------------------- |
| `core/`              | Infrastructure — theme, icons, snacks, treesitter, LSP                                                | `lazy=false`, `priority=CORE(1000)`    |
| `chrome/`            | Visual-only — statusline, decorations, which-key                                                      | `priority=CHROME(900)`                 |
| `features/{domain}/` | Domain features (8 groups: navigation, completion, git, editing, search, diagnostics, formatting, ai) | `event='VeryLazy'` or keymap-triggered |

Import order in `config/lazy/init.lua`: `core` **must be first**. All plugins lazy by default (`defaults.lazy=true`).

### Globals (`lua/config/globals.lua`)

Seven globals available everywhere (six set in `globals.lua`, one by its plugin). `Conf` groups the constant config tables; only `Notifier` is a lazy proxy, `UI`/`Statusline` are required directly:

| Global       | Source                             | Usage                                                                               |
| ------------ | ---------------------------------- | ----------------------------------------------------------------------------------- |
| `Defer`      | `utils.lazy_require`               | `Defer.on_index()`, `Defer.on_exported_call()`                                      |
| `Notifier`   | Lazy proxy → `services.notifier`   | `Notifier.info('msg')`, `Notifier.warn('msg', { title = 'T' })`                     |
| `Conf`       | `config.*` constant tables         | `Conf.icons` (never hardcode icons), `Conf.filetypes` (`M.js`, `M.jsx`, …), `Conf.priority` (`CORE=1000`, `CHROME=900`, `FEATURE=800`), `Conf.picker`, `Conf.size`, `Conf.cmp` |
| `UI`         | `utils.ui` (direct require)        | `UI.catppuccin(fn)` / `UI.which_key(spec)` for spec registration, `UI.popup_config()`, `UI.get_palette('ext')`, `UI.blend_hex()` |
| `Statusline` | `services.statusline` (direct require) | `Statusline.have_status_line()`, `Statusline.refresh()`                        |
| `Project`    | `utils.project_config`             | Per-project overrides from `.neovimrc.json` — `Project.linter`, `Project.formatter` |
| `Snacks`     | Set by snacks.nvim at runtime      | `Snacks.picker.*`, `Snacks.terminal.*`, etc.                                        |

## Plugin Spec Conventions

### Key Order

`'author/repo'` → `enabled`/`cond`/`name`/`branch`/`version`/`build`/`main` → `lazy`/`priority` → `cmd`/`event`/`ft` → `dependencies` → `keys` → `init` → `opts`/`opts_extend` → `config`

### Return Convention

```lua
-- Single spec (majority):
return { 'author/plugin', keys = { ... }, opts = { ... } }

-- List with catppuccin/which-key registration:
return { UI.which_key({ ... }), UI.catppuccin(function(...) ... end), { 'author/plugin', opts = ... } }
```

### Directory Plugins

For plugins with state or large configs: `init.lua` (specs) + `utils.lua` (`M.state = {}`) + optional `config/` sub-modules. See `nvim-tree-lua/`, `blink-cmp/`.

### Popup Sizing

Use `popup_config(size, with_border)`, never hardcode dimensions. **Gotcha**: Telescope always needs `with_border=true`; nvim-tree always needs `false`; Snacks varies by popup variant — `false` for the main pickers (`lg`, `full`, `input`) and `true` for bordered variants like `sm` / `lg_border`.

## LSP Setup

Uses Neovim 0.12+ native `vim.lsp.enable()` / `vim.lsp.config()` (not `lspconfig[server].setup()`). Per-server files live at `core/lsp/nvim-lspconfig/lsp/{server}.lua` — **these are NOT lazy.nvim specs and NOT raw `vim.lsp.Config` tables**. Each file returns `{ opts = table|function, setup = function? }`; `nvim-lspconfig/utils/server_loader.lua` walks the directory, calls `vim.lsp.config(name, opts)`, then invokes `setup()` if present. General LSP keymaps live in `nvim-lspconfig/init.lua`, not server files.

Server-specific `LspAttach` autocmds use an early-return guard on client name — see existing server configs for the pattern.

**Gotcha**: nvim-lspconfig uses `event='VeryLazy'` instead of `LazyFile` to avoid directory file-type detection issues.

## Forks

17 minimal-diff forks by `hareki`. Updated via [wei/pull](https://github.com/wei/pull).
