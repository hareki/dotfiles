# AGENTS.md

This file provides guidance to LLMs when working with code in this repository.

## Overview

Personal Neovim configuration using **lazy.nvim** plugin manager. Targets Neovim 0.11+ with native LSP support.

## Code Style

- **Formatter**: stylua — 100-char lines, 2-space indent, single quotes (see `.stylua.toml`)
- **LuaLS annotations**: `---@class`, `---@param`, `---@return`, `---@alias` for public APIs
- **Requires**: always assign to a local before use — `local x = require('y')` then `x.method()`, never `require('y').method()`
- **Keymaps**: always use `vim.keymap.set()` with `<cmd>...<cr>` strings — never structured `vim.cmd` API. Fall back to function callbacks only when runtime values or multi-statement logic are needed. Always include `desc` in CMOS 18 title case ("Find Files", "Go to Definition")
- **Icons**: always import from `config/icons.lua` via the `Icons` global — never hardcode icon strings

## Architecture

### Boot Order (`init.lua`)

`vim.loader.enable` → `config.globals` → `config.options` → `config.autocmds` → `config.usercmds` → `config.keymaps` → `config.lazy`

### Plugin Tiers (`lua/plugins/`)

| Directory            | Purpose                                                                                               | Load behavior                          |
| -------------------- | ----------------------------------------------------------------------------------------------------- | -------------------------------------- |
| `core/`              | Infrastructure — theme, icons, snacks, treesitter, LSP                                                | `lazy=false`, `priority=CORE(1000)`    |
| `chrome/`            | Visual-only — statusline, decorations, which-key                                                      | `priority=CHROME(900)`                 |
| `features/{domain}/` | Domain features (8 groups: navigation, completion, git, editing, search, diagnostics, formatting, ai) | `event='VeryLazy'` or keymap-triggered |

Import order in `config/lazy/init.lua`: `plugins.core` **must be first**. All plugins lazy by default (`defaults.lazy=true`).

### Globals (`lua/config/globals.lua`)

Seven globals available everywhere (six set in `globals.lua`, one by its plugin):

| Global       | Source                           | Usage                                                           |
| ------------ | -------------------------------- | --------------------------------------------------------------- |
| `Defer`      | `utils.lazy-require`             | `Defer.on_index()`, `Defer.on_exported_call()`                  |
| `Notifier`   | Lazy proxy → `services.notifier` | `Notifier.info('msg')`, `Notifier.warn('msg', { title = 'T' })` |
| `Catppuccin` | `utils.ui.catppuccin`            | Highlight registration in plugin specs                          |
| `WhichKey`   | `utils.ui.which_key`             | Which-key group/rule registration in plugin specs               |
| `Icons`      | `config.icons`                   | All icons — never hardcode icon strings                         |
| `Priority`   | `config.priority`                | `CORE = 1000`, `CHROME = 900`, `FEATURE = 800`                  |
| `Snacks`     | Set by snacks.nvim at runtime    | `Snacks.picker.*`, `Snacks.terminal.*`, etc.                    |

### Key Modules

- `config/size.lua` — popup size presets
- `config/palette_ext.lua` — extended Catppuccin colors
- `config/picker.lua` — shared picker UI constants
- `services/` — cross-cutting concerns (statusline, cursorline, keymap registry, notifier)
- `utils/ui.lua` — popup config helpers, highlight utilities
- `utils/common.lua` — general-purpose helpers

## Plugin Spec Conventions

### Key Order

`'author/repo'` → `enabled`/`cond`/`name`/`branch`/`version`/`build`/`main` → `lazy`/`priority` → `cmd`/`event`/`ft` → `dependencies` → `keys` → `init` → `opts`/`opts_extend` → `config`

### Return Convention

```lua
-- Single spec (majority):
return { 'author/plugin', keys = { ... }, opts = { ... } }

-- List with Catppuccin/WhichKey highlights:
return { WhichKey({ ... }), Catppuccin(function(...) ... end), { 'author/plugin', opts = ... } }
```

### Directory Plugins

For plugins with state or large configs: `init.lua` (specs) + `utils.lua` (`M.state = {}`) + optional `config/` sub-modules. See `nvim-tree/`, `blink-cmp/`.

### Popup Sizing

Use `popup_config(size, with_border)`, never hardcode dimensions. **Gotcha**: Telescope needs `with_border=true`; Snacks/nvim-tree need `false`.

## LSP Setup

Uses Neovim 0.11+ native `vim.lsp.enable()` (not `lspconfig[server].setup()`). Per-server configs in `plugins/core/lsp/nvim-lspconfig/lsp/{server}.lua` — **these are NOT lazy.nvim specs**. General LSP keymaps live in `nvim-lspconfig/init.lua`, not server files.

Server-specific `LspAttach` autocmds use an early-return guard on client name — see existing server configs for the pattern.

**Gotcha**: nvim-lspconfig uses `event='VeryLazy'` instead of `LazyFile` to avoid directory file-type detection issues.

## Forks

16 minimal-diff forks by `hareki`. Updated via [wei/pull](https://github.com/wei/pull). Features toggleable — disabling custom bits reverts to upstream. Enable unified floating UX: **Tab** = toggle focus (list↔preview, float↔main); **`<C-t>`** = toggle side-panel mode.
