# Copilot Instructions for Neovim Config

## Architecture

**lazy.nvim** config with strict one-plugin-per-file under `lua/plugins/{ai,coding,editor,formatting,lsp,treesitter,ui}/`.

### Globals (`lua/config/globals.lua`)

Five globals available everywhere — only `Notifier` is lazy-loaded:

| Global       | Source                        | Usage                                                           |
| ------------ | ----------------------------- | --------------------------------------------------------------- |
| `Defer`      | `utils.lazy-require`          | `Defer.on_index()`, `Defer.on_exported_call()`                  |
| `Notifier`   | Lazy proxy → `utils.notifier` | `Notifier.info('msg')`, `Notifier.warn('msg', { title = 'T' })` |
| `Catppuccin` | `utils.ui.catppuccin`         | Highlight registration in plugin specs                          |
| `Icons`      | `config.icons`                | All icons (diagnostics, git, LSP kinds, explorer)               |
| `Priority`   | `config.priority`             | Loading priority constants (`CORE`, `LAYOUT`)                   |

### Central Modules (`lua/config/`)

| Module            | Purpose                                                                                                   |
| ----------------- | --------------------------------------------------------------------------------------------------------- |
| `size.lua`        | Size presets: `popup` (`sm`/`md`/`lg`/`vertical_lg`/`full`), `side_preview`, `side_panel`, `inline_popup` |
| `icons.lua`       | All icon strings — never hardcode icons, always use `Icons.xxx`                                           |
| `palette_ext.lua` | Extended palette colors (`blue0-2`, `green0-1`, `surface15`) beyond standard catppuccin                   |
| `picker.lua`      | Shared picker UI constants (`prompt_prefix`, `preview_title`)                                             |
| `priority.lua`    | Plugin loading priority constants                                                                         |

### Utils (`lua/utils/`)

| Module             | Key Exports                                                                                                                  |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------- |
| `ui.lua`           | `popup_config(size)`, `catppuccin(fn)`, `get_palette()`, `computed_size(size)`, `highlight()`, `highlights()`, `blend_hex()` |
| `common.lua`       | `noautocmd(fn)`, `focus_win(win)`, `is_float_win()`, `list_extend(...)`                                                      |
| `notifier.lua`     | Rich notifications with highlight support                                                                                    |
| `lazy-require.lua` | `Defer.on_index()`, `Defer.on_exported_call()`                                                                               |

## Plugin Patterns

### Return Convention

All plugin files return a **list of specs** (table of tables), even single-plugin files:

```lua
-- Single plugin (e.g., hlchunk.nvim.lua)
return {
  { 'shellRaining/hlchunk.nvim', event = 'LazyFile', opts = { ... } },
}

-- With Catppuccin highlights (e.g., nvim-tree/init.lua)
return {
  Catppuccin(function(palette, sub_palette, extension) ... end),
  { 'author/dependency', opts = { ... } },
  { 'author/main-plugin', opts = function() ... end },
}
```

### Complex Plugin Structure

For plugins needing state or extensive customization, use a directory:

```
nvim-tree/            -- State + multiple specs
  init.lua            -- Returns list: [1] Catppuccin, [2+] plugin specs
  utils.lua           -- M.state = {} table + helpers

blink-cmp/            -- Large config split into sub-modules
  init.lua            -- Main spec
  utils.lua           -- Shared utilities
  config/             -- Sub-configs: appearance.lua, completion.lua, keymap.lua, sources.lua
```

### Catppuccin Highlight Registration

`Catppuccin` callback receives **3 arguments**: `palette` (mocha), `sub_palette` (latte), `extension` (palette_ext.lua). Use only what you need:

```lua
Catppuccin(function(palette, sub_palette, extension)
  return { MyHl = { fg = palette.blue, bg = extension.blue0 } }
end)

-- Underscore unused args
Catppuccin(function(palette, _, extension)
  return { MyHl = { fg = extension.green1 } }
end)
```

### Popup Sizing

Use `popup_config(size)` from `utils.ui` — never hardcode dimensions:

```lua
local ui = require('utils.ui')
local size = ui.popup_config('lg') -- Returns: { width, height, col, row }
```

### State Management Pattern

Complex plugins use `M.state = {}` in their `utils.lua` with full type annotations:

```lua
---@alias MyPlugin.Position 'side' | 'float'

---@class MyPlugin.State
---@field position MyPlugin.Position

---@type MyPlugin.State
M.state = { position = 'float' }
```

## Conventions

### Plugin Spec Key Order

Strict ordering for lazy.nvim specs:

1. `'author/repo'`
2. `enabled` → `cond` → `name` → `branch` → `version` → `build` → `main`
3. `lazy` → `priority`
4. `cmd` → `event` → `ft`
5. `dependencies`
6. `keys` → `init` → `opts` → `opts_extend` → `config`

**Keymap definitions** within `keys`: `{ lhs, rhs, mode = '...', desc = '...', expr = true, silent = true }`

### Keymaps

- **Always** include `desc` in CMOS 18 title case: "Find Files", "Go to Definition"
- `<A-key>` for Alt bindings; `<leader>` for command groups
- `<A-s>` = format + save; `<leader>F` = format only

### Module Returns

- Always return tables (no global mutation)
- Use LuaLS `---@class` / `---@param` / `---@return` / `---@alias` annotations for public APIs

## LSP Setup

Uses Neovim 0.11+ native `vim.lsp.enable()` (not `lspconfig[server].setup()`). Per-server configs in `lua/plugins/lsp/nvim-lspconfig/lsp/{server}.lua` — each server file defines its own `LspAttach` autocmd with server-name guards for server-specific keymaps. Mason handles tool installation via `lua/plugins/lsp/mason.nvim.lua`.

**Servers**: eslint, jsonls, lua_ls, tailwindcss, typos_lsp, vtsls, yamlls

## Formatting

Single async pipeline in `utils/formatters/async_style_enforcer.lua`:

- `M.run()` — format + lint one buffer (conform.nvim → linters sequentially)
- `M.run_all()` — runs on all modified listed buffers with summary notification
- Buffer locks prevent concurrent operations; 10s timeout auto-cleans stuck locks

## Snacks Picker

Custom pickers live in `lua/plugins/editor/snacks/pickers/`. Each exports `M.show(user_opts)`.

### Supporting Modules (`snacks/utils/`)

| Module             | Key Exports                                                                |
| ------------------ | -------------------------------------------------------------------------- |
| `formatters.lua`   | `keymap_format`, `buffer_format`, `buffer_select_format`                   |
| `transformers.lua` | `files_transform`, `keymap_transform`, `buffer_select_transform`           |
| `sorters.lua`      | Custom sorting functions                                                   |
| `cache.lua`        | Query result caching for transformers                                      |
| `state.lua`        | Per-picker state persistence (e.g., files picker remembers preview toggle) |

`picker_query_persister.lua` — persists search queries (grep, files) across picker invocations.

## Plugin Import Order

In `config/lazy/init.lua`, `plugins.ui` **must be imported first** for `Catppuccin` to work:

```lua
spec = {
  { import = 'plugins.ui' }, -- Must be first
  { import = 'plugins.ai' },
  ...
}
```

All plugins are lazy by default (`defaults.lazy = true`). Use `event = 'VeryLazy'` or keymap triggers.

## Forks (author = `hareki`)

15+ minimal-diff forks enable unified UX:

- **Tab** = toggle focus (list↔preview, float↔main)
- **`<C-t>`** = toggle side-panel mode
- Updated via [wei/pull](https://github.com/wei/pull); features toggleable

## Code Style

- stylua: 100-char lines, 2-space indent
- LuaLS `---@class` / `---@param` / `---@return` / `---@alias` annotations for public APIs
- Import icons from `config/icons.lua` via `Icons` global — never hardcode icon strings
- Use `Notifier` global for notifications, `Catppuccin` global for highlights

**Module Imports**: Always assign `require()` to a local variable first:

```lua
-- Bad
require('plugins.ui.lualine.utils').refresh_statusline()

-- Good
local lualine_utils = require('plugins.ui.lualine.utils')
lualine_utils.refresh_statusline()
```

**Command Syntax**: Use `vim.cmd` structured API, never `<CMD>...<CR>`:

```lua
-- Bad
map('n', '<leader>q', '<CMD>q<CR>', { desc = 'Quit' })

-- Good
map('n', '<leader>q', vim.cmd.q, { desc = 'Quit' })
map('n', '<leader>s', function() vim.cmd.split({ mods = { split = 'botright' } }) end, { desc = 'Split' })
```
