# CLAUDE.md

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

Six globals available everywhere:

| Global       | Source                           | Usage                                                           |
| ------------ | -------------------------------- | --------------------------------------------------------------- |
| `Defer`      | `utils.lazy-require`             | `Defer.on_index()`, `Defer.on_exported_call()`                  |
| `Notifier`   | Lazy proxy → `services.notifier` | `Notifier.info('msg')`, `Notifier.warn('msg', { title = 'T' })` |
| `Catppuccin` | `utils.ui.catppuccin`            | Highlight registration in plugin specs                          |
| `Icons`      | `config.icons`                   | All icons — never hardcode icon strings                         |
| `Priority`   | `config.priority`                | `CORE = 1000`, `CHROME = 900`                                   |
| `Snacks`     | Set by snacks.nvim               | `Snacks.picker.*`, `Snacks.terminal.*`, etc.                    |

### Key Modules

- `config/size.lua` — popup presets (`sm`/`md`/`lg`/`vertical_lg`/`full`/`side_preview`/`side_panel`/`inline_popup`)
- `config/palette_ext.lua` — extended Catppuccin colors (`blue0-2`, `green0-1`, `surface15`)
- `config/picker.lua` — shared picker UI constants
- `services/` — cross-cutting concerns: `statusline`, `cursorline`, `keymap_registry`, `notifier`
- `utils/ui.lua` — `popup_config(size, with_border)`, `catppuccin(fn)`, `get_palette()`, `blend_hex()`
- `utils/common.lua` — `noautocmd(fn)`, `focus_win(win)`, `is_float_win()`, `list_extend()`

## Plugin Spec Conventions

### Key Order

`'author/repo'` → `enabled`/`cond`/`name`/`branch`/`version`/`build`/`main` → `lazy`/`priority` → `cmd`/`event`/`ft` → `dependencies` → `keys` → `init` → `opts`/`opts_extend` → `config`

### Return Convention

```lua
-- Single spec (majority):
return { 'author/plugin', keys = { ... }, opts = { ... } }

-- List with Catppuccin highlights:
return { Catppuccin(function(palette, sub_palette, extension) ... end), { 'author/plugin', opts = ... } }
```

`Catppuccin(fn)` receives 3 args: `palette` (mocha), `sub_palette` (latte), `extension` (palette_ext). Underscore unused args.

### Directory Plugins

For plugins with state or large configs: `init.lua` (specs) + `utils.lua` (`M.state = {}`) + optional `config/` sub-modules. See `nvim-tree/`, `blink-cmp/`.

### Popup Sizing

Use `popup_config(size, with_border)`, never hardcode dimensions. **Gotcha**: Telescope needs `with_border=true`; Snacks/nvim-tree need `false`.

## LSP Setup

Uses Neovim 0.11+ native `vim.lsp.enable()` (not `lspconfig[server].setup()`). Per-server configs in `plugins/core/lsp/nvim-lspconfig/lsp/{server}.lua` — **these are NOT lazy.nvim specs**:

```lua
return {
  opts = { ... },            -- passed to vim.lsp.config(name, opts)
  setup = function() ... end -- optional: LspAttach autocmds, user commands
}
```

~13 servers enabled; 7 have config files. General LSP keymaps live in `nvim-lspconfig/init.lua`, not server files.

### LspAttach Guard Pattern

Server-specific autocmds early-return on client name mismatch:

```lua
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('{server}_lsp_attach', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not (client and client.name == '{server}') then return end
    -- server-specific setup
  end,
})
```

**Gotcha**: nvim-lspconfig uses `event='VeryLazy'` instead of `LazyFile` to avoid directory file-type detection issues.

## Forks

15+ minimal-diff forks by `hareki`. Updated via [wei/pull](https://github.com/wei/pull). Features toggleable — disabling custom bits reverts to upstream. Enable unified floating UX: **Tab** = toggle focus (list↔preview, float↔main); **`<C-t>`** = toggle side-panel mode.
