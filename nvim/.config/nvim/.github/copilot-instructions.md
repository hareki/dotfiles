# Copilot Instructions for Neovim Config

## Architecture Overview

This is a **lazy.nvim**-based Neovim config with strict one-plugin-per-file organization. Plugins are categorized under `lua/plugins/{ai,coding,editor,formatting,lsp,treesitter,ui}/`.

**Central Config Modules** (`lua/configs/`):

- `size.lua` - Shared popup/window dimensions (sm, md, lg, full, vertical_lg)
- `color.lua` - Custom color constants
- `icons.lua` - Unified icon definitions
- `picker.lua` - Shared picker UI constants
- `globals.lua` - Global `_G.Defer` and `_G.Notifier` lazy-loading proxies

**Shared Utilities** (`lua/utils/`):

- `ui.lua` - `popup_config()`, `catppuccin()` for consistent layouts/theming
- `common.lua` - `noautocmd()`, `focus_win()` helpers
- `lazy-require.lua` - Deferred module loading (`on_index`, `on_exported_call`)
- `notifier.lua` - Custom notification system with highlight support

## Key Conventions

### Plugin File Structure

Complex plugins use `{plugin}/init.lua` + `{plugin}/utils.lua` pattern:

```
nvim-tree/
  init.lua   -- Plugin spec + config
  utils.lua  -- State management + helpers
  types.lua  -- Type definitions (optional)
```

### Catppuccin Integration Pattern

Use `require('utils.ui').catppuccin()` to register custom highlights:

```lua
return {
  require('utils.ui').catppuccin(function(palette, sub_palette)
    return { MyHighlight = { fg = palette.blue } }
  end),
  { 'plugin/name', opts = {...} },
}
```

### Keymap Conventions

- All keymaps require `desc` in **CMOS 18 title case** (e.g., "Find Files", "Go to Definition")
- Use `<A-key>` for Alt bindings, `<leader>` prefix for command groups
- Format/save: `<A-s>` runs async formatter pipeline

### Formatting Pipeline

Single async pipeline via `utils/formatters/async_style_enforcer.lua`:

- Runs conform.nvim formatters → linters sequentially
- Prevents concurrent operations with buffer locks
- Use `require('utils.formatters.async_style_enforcer').run()` for format+save

### Popup Size System

Always use `configs/size.lua` dimensions via `require('utils.ui').popup_config(size)`:

- `'sm'`, `'md'`, `'lg'`, `'vertical_lg'`, `'full'` presets
- Automatically handles borders, min dimensions, centering

### LSP Configuration

Individual LSP configs live in `lua/plugins/lsp/nvim-lspconfig/lsp/{server}.lua`. Mason auto-installs specified tools.

## Forks & Custom Behavior

15+ forked plugins (author = `hareki`) enable unified UX via minimal patches:

- Tab = toggle focus between list/preview or float/main window
- `<C-t>` = toggle side-panel mode where supported
- Forks expose hooks upstream doesn't provide yet

## Code Style

- **Lua**: stylua formatter, 100-char lines, 2-space indent
- Return tables from modules (no global mutation)
- Lazy-load aggressively: `event = 'VeryLazy'` or keymap triggers
- Use `Notifier.info/warn/error()` for user notifications
