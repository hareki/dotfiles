# Copilot Instructions for Neovim Config

## Architecture

**lazy.nvim** config with strict one-plugin-per-file under `lua/plugins/{ai,coding,editor,formatting,lsp,treesitter,ui}/`.

### Central Modules (`lua/configs/`)

| Module        | Purpose                                                   |
| ------------- | --------------------------------------------------------- |
| `size.lua`    | Popup dimensions: `sm`, `md`, `lg`, `vertical_lg`, `full` |
| `icons.lua`   | All icons (diagnostics, git, file status, LSP kinds)      |
| `globals.lua` | `_G.Notifier` and `_G.Defer` lazy proxies                 |
| `picker.lua`  | Shared picker UI constants                                |

### Utils (`lua/utils/`)

| Module             | Key Exports                                             |
| ------------------ | ------------------------------------------------------- |
| `ui.lua`           | `popup_config(size)`, `catppuccin(fn)`, `get_palette()` |
| `common.lua`       | `noautocmd(fn)`, `focus_win(win)`, `is_float_win()`     |
| `notifier.lua`     | Rich notifications with highlight support               |
| `lazy-require.lua` | `Defer.on_index()`, `Defer.on_exported_call()`          |

## Plugin Patterns

### Complex Plugin Structure

For plugins requiring state management or extensive customization:

```
nvim-tree/
  init.lua   -- Returns table: [1] catppuccin highlights, [2] plugin spec
  utils.lua  -- M.state = {} table + helper functions
  types.lua  -- LuaLS @class annotations (optional)
```

### Catppuccin Highlight Registration

When plugin needs custom highlights, place `catppuccin()` first in returned table:

```lua
return {
  require('utils.ui').catppuccin(function(palette, sub_palette)
    return { MyHighlight = { fg = palette.blue, bg = palette.base } }
  end),
  { 'plugin/name', opts = {...} },
}
```

### Popup Sizing

Use `require('utils.ui').popup_config(size)` — never hardcode dimensions:

```lua
local size = require('utils.ui').popup_config('lg')
-- Returns: { width, height, col, row }
```

### State Management Pattern

Complex plugins use `M.state = {}` in their `utils.lua`:

```lua
---@class MyPlugin.Utils
local M = {}

M.state = {
  position = 'float',
  preview_on_focus = false,
}
```

## Conventions

### Plugin Spec Key Order

**lazy.nvim** plugin specs must follow this exact key order:

1. `plugin name` (string, e.g., `'author/repo'`)
2. `enabled` → `cond` → `name` → `branch` → `version` → `build` → `main`
3. `lazy` → `priority`
4. `cmd` → `event` → `ft`
5. `dependencies`
6. `keys` → `init` → `opts` → `opts_extend` → `config`

**Keymap definitions** within `keys` follow this order:

```lua
{ lhs, rhs, mode = '...', desc = '...', expr = true, silent = true }
```

Order: **lhs** → **rhs** → **mode** → **desc** → **expr** → **silent**

### Keymaps

- **Always** include `desc` in CMOS 18 title case: "Find Files", "Go to Definition"
- `<A-key>` for Alt bindings; `<leader>` for command groups
- `<A-s>` = format + save; `<leader>F` = format only

### Notifications

Use global `Notifier` (auto lazy-loaded via `globals.lua`):

```lua
Notifier.info('Message')
Notifier.warn('Warning', { title = 'Title' })
```

### Module Returns

- Always return tables (no global mutation)
- Use LuaLS `---@class` annotations for public module APIs

## LSP Setup

Per-server configs in `lua/plugins/lsp/nvim-lspconfig/lsp/{server}.lua`. Mason handles tool installation via `lua/plugins/lsp/mason.nvim.lua`.

## Formatting

Single async pipeline in `utils/formatters/async_style_enforcer.lua`:

- Runs conform.nvim → linters sequentially
- Buffer locks prevent concurrent operations
- Call: `require('utils.formatters.async_style_enforcer').run()`

## Snacks Picker

Custom pickers live in `lua/plugins/ui/snacks/pickers/`. Each exports a function:

```lua
-- pickers/harpoon.lua
return function(user_opts)
  local items = build_items()
  local opts = vim.tbl_deep_extend('force', { title = 'Harpoon', items = items }, user_opts or {})
  return Snacks.picker(opts)
end
```

**Existing pickers**: `harpoon` (see `pickers/harpoon.lua` for pattern)

**Shared utilities** (`snacks/utils.lua`):

- `buffer_format` — consistent buffer item formatting
- `keymap_transform` — enriches keymap items with which-key descriptions

**Invocation pattern** (from keymaps in `snacks/init.lua`):

```lua
require('plugins.ui.snacks.pickers.harpoon').show({ preview = 'main' })
```

## Forks (author = `hareki`)

15+ minimal-diff forks enable unified UX:

- **Tab** = toggle focus (list↔preview, float↔main)
- **`<C-t>`** = toggle side-panel mode
- Updated via [wei/pull](https://github.com/wei/pull); features toggleable

## Code Style

- stylua: 100-char lines, 2-space indent
- Lazy-load via `event = 'VeryLazy'` or keymap triggers
- LuaLS `---@class` / `---@param` / `---@return` annotations for public APIs
- Import icons from `configs/icons.lua` — never hardcode icon strings
