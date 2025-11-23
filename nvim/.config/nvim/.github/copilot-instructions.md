# Neovim Config AI Agent Guide

## Snapshot

- Goal: keep startup near 40 ms while preserving unified float UX supplied by `hareki/*` forks.
- Boot chain: `init.lua` → `configs/{globals,options,autocmds,keymaps}` → `configs.lazy`.
- Lazy import order in `lua/configs/lazy/init.lua` is fixed: `ui` → `ai` → `coding` → `editor` → `formatting` → `lsp` → `treesitter` (do not reorder; catppuccin relies on UI first).
- Each plugin lives in `lua/plugins/<category>/<name>.lua`; shared helpers sit in `lua/utils/` (e.g., `ui.lua`, `common.lua`).

## File Map

- Core config: `lua/configs/*.lua` (options, keymaps, autocmds, picker, size tokens).
- Sizing/layout tokens: `lua/configs/size.lua`; always pull via `require('configs.size')` + `require('utils.ui').popup_config/telescope_layout`.
- UI helpers/theme: `lua/utils/ui.lua` + `lua/plugins/ui/catppuccin.nvim.lua` (extends palette through `ui.catppuccin`).
- Fork-heavy UX surfaces: `lua/plugins/editor/eagle.nvim.lua`, `.../nvim-tree`, `.../snacks`, `.../gitsigns`, `.../telescope`—they share Tab/<C-t> handling.
- Formatting & lint orchestration lives only in `lua/utils/formatters/async_style_enforcer.lua` triggered by `<A-s>` from `configs/keymaps.lua`.

## Critical Patterns

1. Sizing/layout: never hardcode floats; reuse popup/side tokens and `utils.ui` helpers so Snacks/Telescope/NvimTree look identical.
2. Float UX: Tab toggles list↔preview (or float↔main), `<C-t>` toggles side-panel mode; extend this contract when adding pickers or previews.
3. Fork preservation: `hareki/*` forks expose custom hooks (layout, focus toggles, preview sync). Keep diffs minimal and behind opts flags.
4. Theme integration: inject highlights through `require('utils.ui').catppuccin(function(p) ... end)` instead of `vim.api.nvim_set_hl`. Audit `plugins/ui/catppuccin.nvim.lua` before touching globals.
5. Plugin specs: return Lazy tables, configure via `opts` callbacks, keep state module-local or in `lua/utils/`. Use `lazy.require_on_*` helpers for deferred requires.

## Workflows

- Formatting/linting: `<A-s>` triggers async pipeline (Conform + ESLint) via `async_style_enforcer`. Extend only there; do not add new commands/autocmds.
- Profiling/perf: run `:Lazy profile` after heavy changes; cold start budget ~38 ms (dashboard) / ~50 ms (file).
- Validation loop: `:Lazy sync`, `:Lazy profile`, `:checkhealth`, then test key UX (Snacks picker `<leader><leader>`, nvim-tree `<C-n>`, formatter `<A-s>`). Watch `:messages` for regressions.
- Tooling: stylua formats Lua (`stylua lua/`); Telescope/Ripgrep/fd/lazygit are expected runtime deps; ensure sqlite3 for yanky/auto-session builds.

## Conventions

- Keymaps require CMOS Title Case `desc` and usually live in `lua/configs/keymaps.lua` (plugin-local keys OK within specs).
- Notifications go through `require('utils.notifier')`; progress indicators through `require('utils.progress')`.
- Use `utils.common.noautocmd/focus_win` when manipulating windows during float UX tweaks.
- No new globals beyond `_G.lazy` and `_G.notifier`; prefer module locals or utilities.

## Anti-Patterns

- ❌ Hardcoding float dimensions/positions; always consume `configs.size` + `utils.ui` helpers.
- ❌ Calling `vim.notify` or bypassing `utils.notifier` (breaks theme consistency and markdown rendering).
- ❌ Reordering `lua/configs/lazy/init.lua` imports or loading UI plugins out of sequence.
- ❌ Adding competing format commands/autocmds outside `async_style_enforcer`.
- ❌ Removing Tab/<C-t> focus toggles from floats or skipping shared layout primitives.
