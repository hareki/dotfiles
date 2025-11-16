# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a from-scratch Neovim configuration (~9,234 lines of Lua) optimized for fast cold starts (38-50ms), consistent floating UX, and maintainable per-plugin isolation. It uses 15+ minimal-diff forks to achieve a unified design language across disparate plugins.

## Key Commands

### Formatting
```bash
stylua lua/  # Format Lua code according to .stylua.toml
```

### Plugin Management
```vim
:Lazy         # Open Lazy UI
:Lazy sync    # Update plugins
:Lazy profile # Check startup performance
```

### Validation Workflow
After making changes, run:
1. `:Lazy sync` - Sync plugins
2. `:Lazy profile` - Check for performance regressions
3. `:checkhealth` - Verify setup
4. Test key flows: formatting (`<A-s>`), pickers (`<leader><leader>`), nvim-tree (`<C-n>`)
5. Check `:messages` for errors

### Formatter/Linter Status
```vim
:ConformInfo  # Check formatter status
:EslintLog    # View ESLint debug log
```

## Architecture

### Boot Sequence
`init.lua` → loads in order:
1. `vim.loader.enable(true)` - Byte-caching
2. `configs.globals` - Sets up `_G.lazy` and `_G.notifier`
3. `configs.options` - Vim options
4. `configs.autocmds` - Autocommands
5. `configs.usercmds` - Custom commands
6. `configs.keymaps` - Global keymaps
7. `configs.lazy` - Lazy.nvim plugin manager

### Plugin Loading Order (Critical)
`lua/configs/lazy/init.lua` imports in fixed order:
```lua
ui → ai → coding → editor → formatting → lsp → treesitter
```
**Important:** UI must be first (catppuccin theme dependency).

### File Organization
- `lua/configs/` - Core configuration modules
- `lua/plugins/<category>/` - One plugin per file (70 plugins total)
- `lua/utils/` - Shared utility modules (15 files)
- `snippets/` - VSCode-style snippets

## Critical Design Patterns

### 1. Centralized Sizing System
**Never hardcode dimensions.** Use tokens from `lua/configs/size.lua`:
```lua
-- Size tokens
popup.{full, lg, md, sm, vertical_lg}  -- Modal/float sizes
side_preview.md                         -- Side preview dimensions
side_panel.md                           -- Sidebar dimensions

-- Usage
local utils = require('utils.ui')
local config = utils.popup_config('md', true)  -- medium size, with border
local layout = utils.telescope_layout('lg')     -- large telescope layout
```

### 2. Unified Float UX Contract
All floats must follow this behavior:
- **Tab** - Toggle focus between list/preview or float/main window
- **Ctrl+T** - Toggle side-panel mode (results dock + floating preview)

Implemented in: Snacks picker, Telescope, nvim-tree, gitsigns, eagle.

### 3. Fork Preservation
18 plugins use `hareki/*` forks with minimal diffs:
- Keep custom APIs intact when updating
- Features are toggleable to revert to upstream behavior
- Auto-updated via [wei/pull](https://github.com/wei/pull)
- Mirror minimal-diff style when modifying

Examples: `eagle.nvim`, `snacks.nvim`, `mini.ai`, `trouble.nvim`, `nvim-tree`

### 4. Notification System
**Always use** `utils/notifier.lua` instead of `vim.notify()`:
```lua
local notifier = require('utils.notifier')
notifier.info('Message')
notifier.warn('Warning')
notifier.error('Error')
notifier.debug('Debug info')

-- Supports markdown and custom highlights
notifier.info({{"Bold text", "Bold"}, " normal text"})
```

### 5. Progress Tracking
For async operations, use `utils/progress.lua`:
```lua
local progress = require('utils.progress')
progress.start('Operation name')
-- ... do work ...
progress.finish()
```

### 6. Theme & Palette
- Base theme: Catppuccin Mocha
- Inject custom highlights:
```lua
local ui = require('utils.ui')
ui.catppuccin(function(palette)
  return {
    MyHighlight = { fg = palette.blue, bg = palette.surface0 }
  }
end)
```
- Get palette: `require('utils.ui').get_palette()`

## Code Style

### Lua Formatting (.stylua.toml)
- 100 column width
- 2 spaces indentation
- Single quotes preferred
- Always use call parentheses
- Trailing commas

### Keymap Conventions
- All keymaps must have `desc` in **CMOS Title Case**
- Examples: "Find Files", "Go to Definition", "Format and Save"

### Module Structure
- Use EmmyLua annotations for type safety
- Keep module-local state (avoid globals except `_G.lazy`, `_G.notifier`)
- Create sibling `utils.lua` files for plugin-specific helpers
- Never mutate globals in plugin specs

### Plugin Spec Pattern
```lua
return {
  'author/plugin',
  event = 'VeryLazy',  -- or keys/cmd/ft for lazy loading
  opts = function(_, opts)
    -- Modify opts here
    return opts
  end,
  config = function(_, opts)
    require('plugin').setup(opts)
  end,
}
```

## Key Utilities

### `lua/utils/ui.lua`
```lua
-- Screen size calculation
M.screen_size() -> width, height

-- Popup window configuration (respects size tokens)
M.popup_config(size, with_border) -> {width, height, col, row}

-- Telescope layout helpers
M.telescope_layout(size) -> telescope-compatible config

-- Catppuccin integration
M.catppuccin(register_fn) -> plugin spec for extending highlights

-- Palette access
M.get_palette(name?) -> palette table
```

### `lua/utils/common.lua`
```lua
M.noautocmd(fn)           -- Execute without triggering autocommands
M.focus_win(win)          -- Focus window without autocmds
M.is_float_win(win)       -- Check if window is floating
M.list_extend(...)        -- Merge multiple arrays
```

### `lua/utils/lazy-require.lua`
```lua
lazy.require_on_index(path)        -- Load on first access
lazy.require_on_module_call(path)  -- Load on call
lazy.require_on_exported_call(path) -- Load when method called
```

## Formatting & Linting Pipeline

### Unified Pipeline
**Location:** `lua/utils/formatters/async_style_enforcer.lua`
**Trigger:** `<A-s>` keymap

**Flow:**
1. Check if already running (prevent concurrent ops)
2. Start progress indicator
3. Run formatters via conform.nvim (async)
4. Run linters by filetype (async)
5. Save file
6. Finish progress

**Extend the pipeline here** - don't create new commands or autocommands.

### Registered Formatters (conform.nvim)
- JavaScript/TypeScript/React: prettierd → prettier (stop after first)
- Lua: stylua
- TOML: taplo

### Registered Linters
- ESLint for JS/TS via `utils/linters/eslint.lua`
- Register new linters via `utils/linters/init.lua`

## LSP Configuration

**Location:** `lua/plugins/lsp/nvim-lspconfig.lua`

**Enabled Servers (12):**
- marksman (Markdown)
- lua_ls (Lua)
- taplo (TOML)
- yamlls (YAML)
- vtsls (TypeScript)
- typos_lsp (Spell checker)
- eslint (JS/TS linter)
- jsonls (JSON)
- html (HTML)
- cssls (CSS)
- css_variables (CSS)
- copilot (GitHub Copilot LSP)

## Completion System (blink.cmp)

**Location:** `lua/plugins/coding/blink.cmp.lua`

**Source Priority:**
1. lazydev (Neovim Lua API)
2. lsp
3. path
4. snippets
5. buffer (max 6)
6. spell (max 3, min 4 chars)
7. copilot (max 3, score offset +100)

**Custom Completion Kinds:**
Register via `register_kind()` helper in the spec.

**Copilot Integration:**
- Max 3 completions via blink-copilot
- Hides suggestions when blink menu is open

## Snippets

**Location:** `/snippets/`

**Format:** VSCode-style JSON with `package.json` manifest

**Languages:**
- `all.json` - All filetypes
- `lua.json` - Lua
- `js-shared.json` - JS/TS shared
- `react-shared.json` - React shared
- `typescriptreact.json` - TSX specific

Keep bodies editor-agnostic and follow existing naming conventions.

## Adding New Features

### Adding a New Plugin
1. Create `lua/plugins/<category>/<plugin-name>.lua`
2. Return plugin spec with lazy-loading triggers
3. Use size tokens from `configs/size.lua` for any UI elements
4. Follow float UX contract if adding floating windows
5. Use notifier/progress utilities for feedback
6. Add keymaps with Title Case `desc`

### Adding a New Category
1. Create `lua/plugins/<category>/init.lua`
2. Add `{ import = 'plugins.<category>' }` to `lua/configs/lazy/init.lua`
3. Place in correct import order (respect dependencies)

### Extending Formatting Pipeline
Edit `lua/utils/formatters/async_style_enforcer.lua`:
- Add formatters to conform.nvim config
- Register linters in `lua/utils/linters/init.lua`
- Don't create separate commands/autocommands

### Adding UI Elements
1. **Never hardcode dimensions** - use `configs/size.lua` tokens
2. Use `utils.ui.popup_config()` for floating windows
3. Follow Tab/Ctrl+T UX contract for floats
4. Use `utils.ui.catppuccin()` for theme integration
5. Grep for `popup_config`, `telescope_layout`, `side_panel` to audit impacts

### Adding Keymaps
In `lua/configs/keymaps.lua`:
```lua
vim.keymap.set('n', '<leader>x', function()
  -- your code
end, { desc = 'Description in Title Case' })
```

## Common Pitfalls

1. **Hardcoding dimensions** - Always use size tokens
2. **Direct vim.notify()** - Use `utils/notifier.lua`
3. **Breaking fork APIs** - Preserve custom hooks when updating forks
4. **Wrong import order** - UI must be imported first
5. **Multiple format commands** - Extend the single pipeline
6. **Inconsistent keymaps** - Use Title Case descriptions
7. **Global mutations** - Keep state in module-local or utils
8. **Ignoring lazy loading** - Use event/keys/cmd/ft triggers
9. **Float UX violations** - Follow Tab/Ctrl+T contract

## Performance Considerations

- Cold start target: ~38ms (dashboard) / ~50ms (file open)
- Use lazy loading: `event = 'VeryLazy'` or specific triggers
- Avoid loading on startup unless essential
- Profile after changes: `:Lazy profile`
- Disabled built-ins: netrw, gzip, matchparen, etc. (13 total)

## External Dependencies

### Required
- **Formatters:** stylua, prettierd/prettier, taplo
- **LSP Servers:** marksman, lua_ls, taplo, yamlls, vtsls, typos_lsp, eslint, jsonls, html, cssls, css_variables
- **Build Tools:** C compiler (telescope-fzf-native), sqlite3 (yanky, auto-session)

### Optional
- lazygit (Snacks integration)
- ripgrep (Telescope grep)
- fd (Telescope file search)

## Reference Files

For more detailed patterns, consult:
- `.github/copilot-instructions.md` - Comprehensive AI agent guide
- `lua/plugins/editor/` - Examples of complex plugin configurations
- `lua/plugins/coding/` - Examples of coding tool integrations
- `lua/utils/ui.lua` - UI helper reference implementation

## When Extending

1. **Mirror established patterns** - Check sibling specs before inventing new abstractions
2. **Validate thoroughly** - Run the validation workflow after changes
3. **Maintain fork parity** - Keep minimal-diff style in custom forks
4. **Preserve conventions** - Keymaps, sizing, notifications, progress tracking
5. **Document decisions** - Add comments for non-obvious choices
6. **Test key flows** - Format/save, pickers, tree, LSP actions

## Questions or Uncertainties

If unclear about:
- **Layout/sizing** - Check `lua/configs/size.lua` and `lua/utils/ui.lua`
- **Plugin patterns** - Review sibling specs in same category
- **Fork modifications** - Maintain minimal-diff approach
- **UI/UX contracts** - Follow Tab/Ctrl+T behavior
- **Pipeline extensions** - Modify existing async_style_enforcer

When in doubt, ask before introducing new abstractions.
