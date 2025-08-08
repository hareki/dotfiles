# Neovim Configuration Copilot Instructions

This is a modular Neovim configuration built on lazy.nvim with a structured plugin architecture inspired by kickstart.nvim and LazyVim.

## Architecture Overview

### Core Structure

- **Entry Point**: `init.lua` loads core configs sequentially: globals → options → autocmds → keymaps → lazy
- **Plugin Organization**: Plugins are categorized into directories: `ai/`, `coding/`, `editor/`, `formatting/`, `linting/`, `lsp/`, `treesitter/`, `ui/`
- **Utilities**: Custom utilities in `utils/` provide reusable functionality across plugins
- **Configuration**: Shared configs in `configs/` handle options, keymaps, and lazy.nvim setup

### Key Patterns

#### Plugin Definition Standard

All plugins follow the lazy.nvim spec pattern:

```lua
return {
  'plugin/name',
  event = 'VeryLazy', -- or cmd, keys, ft, etc.
  dependencies = { 'dep/plugin' },
  opts = {}, -- or config = function() ... end
  keys = {
    { '<leader>key', '<cmd>Command<cr>', desc = 'Description' },
  },
}
```

#### Utility Module Pattern

- Global utilities are exposed via `_G.notifier = require('utils.notifier')` in `configs/globals.lua`
- Complex utilities use registry patterns (see `utils/linters/init.lua` for linter registration)
- UI sizing is standardized via `configs/size.lua` with responsive dimensions

#### Configuration Patterns

- **Keymaps**: Use `desc` for which-key integration, group by `<leader>` prefixes
- **Events**: Prefer `VeryLazy` over `LazyFile` to avoid file type detection issues
- **Dependencies**: Always list plugin dependencies explicitly
- **Lazy Loading**: Most plugins are lazy-loaded except themes (`lazy = false, priority = 1000`)

### Critical Workflows

#### Style Enforcement

The `async_style_enforce()` function in `configs/keymaps.lua` orchestrates:

1. Format with conform.nvim
2. Run all registered linters sequentially
3. Auto-save if changes were made
4. Progress reporting via custom progress utility

#### Plugin Management

- Use `lazy-lock.json` for version pinning
- Categories are auto-imported in `configs/lazy/init.lua` via `{ import = 'plugins.category' }`
- Complex plugins get subdirectories (e.g., `nvim-tree/`, `mini-ai/`)

### Integration Points

#### Theme Integration

- **Catppuccin**: Centralized in `plugins/ui/catppuccin.nvim.lua` with custom highlights
- **Icons**: Standardized via `configs/icons.lua` for consistent UI
- **Borders**: Rounded borders are the standard (`border = 'rounded'`)

#### LSP Ecosystem

- **Base**: `nvim-lspconfig` with diagnostic configuration and custom handlers
- **Completion**: blink.cmp integration with snippet support
- **Actions**: actions-preview.nvim for enhanced code actions
- **Development**: lazydev.nvim for Lua development with type checking

#### File Management

- **Explorer**: nvim-tree with custom preview integration and floating/side modes
- **Search**: Telescope with fzf-native backend and custom pickers
- **Navigation**: Harpoon for file bookmarking

### Development Conventions

#### Custom Utilities

- **Notifier**: Rich notification system with highlight support (`utils/notifier.lua`)
- **Progress**: Async progress reporting (`utils/progress.lua`)
- **Linters**: Plugin-agnostic linter registry (`utils/linters/`)
- **Size**: Responsive UI dimensions (`configs/size.lua`)

#### Error Handling

- Notifications use custom notifier with highlight groups
- LSP diagnostics show on current line with custom underline colors
- Float windows have consistent styling with proper borders

#### Performance Optimizations

- Byte-caching enabled with `vim.loader.enable(true)`
- Disabled built-in plugins listed in `configs/lazy/init.lua`
- Strategic lazy loading with appropriate events

### File Naming

- Plugin files match the plugin name exactly (e.g., `telescope.nvim.lua`)
- Complex plugins get directories with `init.lua` + utility modules
- Utilities use descriptive names without `.nvim` suffix
