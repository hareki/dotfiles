# AI Assistant Project Instructions

Purpose: Provide just-enough context so an AI agent can safely extend / refactor this Neovim config without breaking core conventions.

## 1. High-Level Architecture

- **Bootstrap sequence**: `init.lua` enables Lua loader caching, then loads `configs/*` in order: globals → options → autocmds → usercmds → keymaps → lazy. Nothing else should be required at startup.
- **Plugin management**: `lua/configs/lazy/` contains setup (`init.lua`) + bootstrap utilities (`utils.lua`). All plugins are declared by feature area using `spec` imports (`plugins/ui`, `plugins/ai`, `plugins/coding`, `plugins/editor`, `plugins/formatting`, `plugins/lsp`, `plugins/treesitter`). New functionality → add a file under an existing feature folder or a new folder + add `{ import = 'plugins.<folder>' }` to the spec list (ordering matters: UI first to expose palette helpers early).
- **UI sizing & layout system**: Centralized in `configs/size.lua` + `utils/ui.lua` (popup centering, adaptive width/height, palette-driven highlight injection for Catppuccin). Uses semantic size tokens (`sm|md|lg|full|input`) with responsive behavior. Reuse these instead of hard‑coding numbers.
- **State & behavior wrappers**: Many plugin configs expose small utility modules under `lua/plugins/**/<plugin>/utils.lua` or shared helpers under `lua/utils/` (formatters, notifier, progress, git, path, buffer, ui, etc.). Prefer extending these instead of duplicating logic.

## 2. Core Conventions

- **Leader key**: `<Space>` (set early in `configs/options.lua`). Do not change; all mappings assume this.
- **Signcolumn merge**: `opt.signcolumn = 'number'` merges signs with line numbers. Avoid plugins that assume separate signcolumn width without testing.
- **Floating windows**: Use `utils.ui.popup_config(size, with_border?)` for consistent centering & size tokens: `sm|md|lg|full|input` (adds border compensation optionally). Side panels/pair previews derive from `configs/size.lua` (`side_panel`, `side_preview`).
- **Color scheme integration**: Add Catppuccin overrides via `require('utils.ui').catppuccin(function(palette, latte) return { Group = { fg = palette.text } } end)` inside a plugin spec item placed BEFORE the target plugin loads.
- **Plugin spec pattern**: Return Lua table; keep options in `opts = function(_, opts) return opts end` to allow merging. Avoid mutating unrelated global tables.
- **Lazy loading preference**: Default to `lazy = true`. Only force eager load (`lazy = false, priority = 1000`) when a plugin must patch something globally very early (like colorschemes).
- **Performance optimizations**: Core Vim plugins are disabled in `configs/lazy/init.lua` performance section. Lua loader caching enabled in `init.lua`.

## 3. Keymaps & Input Patterns

- **Global keymaps**: Centralized in `configs/keymaps.lua`. When adding user-level maps, place them there unless tightly coupled to a plugin (then define inside that plugin's `on_attach` or `keys` entry). Always provide a `desc` for discoverability (which-key integration implied).
- **Custom trimming logic**: `yy` → `^yg_` (yank trimmed), `dd` → custom function that trims then blackholes remainder. Do not override casually. If adding similar motions, follow that pattern (operate visually, blackhole register when appropriate).
- **Diagnostic navigation**: Uses helper `diagnostic_goto(next, severity)` pattern (copy that style for new severity-filtered motions).
- **Format & save**: `<A-s>` triggers `utils/formatters/async_style_enforcer.lua` for async formatting + linting workflow.
- **Special cursor config**: Complex `guicursor` setup in `options.lua` with mode-specific blinking. Don't modify without understanding the pattern.

## 4. Plugin Integration Patterns (Examples)

- **Nvim-tree**: Custom dual-mode (float vs side) layout orchestrated via `plugins/editor/nvim-tree/` and a local `state` object. Functions like `tree.open()`, `tree.toggle_preview()`, and dynamic sizing rely on `configs/size` + `utils.ui`. When extending, respect `state.position` and avoid hard-coded window dimensions.
- **Notifications**: Use `utils/notifier.lua` instead of `vim.notify` directly for consistent markdown + highlight reapplication with tuple syntax `{{text, hl_group}, ...}`.
- **Formatting**: Asynchronous style enforcement via `utils/formatters/async_style_enforcer.lua`; formatting keymap `<A-s>` triggers that. Hook into that runner if adding new format steps.
- **Telescope**: Uses `utils.ui.telescope_layout(size)` for consistent popup sizing. Custom highlight integration follows the Catppuccin pattern.
- **Completion**: Blink.cmp with custom `register_kind()` function for extending completion types. Copilot integration limited to `copilot_max_items = 3`.

## 5. Adding a New Plugin (Checklist)

1. Pick the feature directory (`lua/plugins/<area>/`). If new area: create folder + add an import entry in `configs/lazy/init.lua` (maintain logical ordering: UI first, then tooling layers).
2. Create `<plugin-name>.lua` returning a spec table. Include: repo string, `event`/`keys`/`ft` for lazy triggers, `opts = function(_, opts) return opts end` pattern for extendability, and `config = function(_, opts) require('<module>').setup(opts) end` when needed.
3. Reuse shared helpers: sizing (`utils.ui`), palette injection, notifier, path/git utilities.
4. Provide meaningful `desc` fields for all keymaps.
5. Avoid global mutations; keep state local or in a dedicated `utils.lua` under the plugin folder if reused across spec pieces.

## 6. Safe Refactor Guidelines

- Before altering size math or popup behavior, inspect both `configs/size.lua` and any plugin utilities consuming it (e.g. telescope, nvim-tree). Changes often cascade.
- Do not rename exported helper module files (`utils/ui.lua`, `configs/size.lua`) without updating every reference; they are widely required.
- When adding highlights, ensure groups won't clash with existing Catppuccin ones; prefer explicit new group names over overriding unless intentional.

## 7. Testing & Validation Workflow

- There is no automated test harness; manual validation happens by launching Neovim and triggering lazy load events.
- After adding plugins or refactors: open Neovim, run `:Lazy sync`, then `:checkhealth` for core health. Use `:messages` + notifier surfaces for runtime errors.
- For performance issues, verify disabled built-ins list in `configs/lazy/init.lua` still aligns with changes.

## 8. Snippets & Completion

- **Snippets**: Live under `snippets/` (various language JSON files). Follow existing naming & shared snippet split (`*-shared.json`). Add new snippet files with clear language-specific scope.
- **Completion**: Blink.cmp backend configured in `plugins/coding/blink.cmp.lua`. Uses custom `register_kind()` for extending completion types. Follow the same pattern if extending sources.
- **Copilot integration**: Limited to max 3 items via `copilot_max_items` constant. Custom kind registration with specific highlight group `BlinkCmpKindCopilot`.

## 9. Style & Formatting

- **Stylua config**: `.stylua.toml` defines formatting rules (respect it). When generating Lua, prefer trailing commas in multiline tables and aligned style similar to existing files.
- **EmmyLua annotations**: Keep modules annotated with EmmyLua-style comments (`---@class`, `---@param`) when adding public helpers.
- **Async formatting workflow**: `utils/formatters/async_style_enforcer.lua` handles formatting + linting with progress reporting. Integrates with conform.nvim and custom linters.

## 10. Common Pitfalls

- **Forgetting imports**: Forgetting to include a new feature folder in the lazy spec import (plugin never loads).
- **Hard-coded dimensions**: Hard-coding window sizes (breaks responsiveness & float/side duality).
- **Early setting overrides**: Overriding leader or cursor settings before plugins load (mapping drift).
- **Inconsistent notifications**: Direct `vim.notify` usage causing inconsistent highlighting vs `utils.notifier`.
- **Highlight conflicts**: Adding highlights without checking existing Catppuccin integration patterns.

## 11. When Unsure

- Search for an existing pattern in `lua/plugins/**` before introducing a new style.
- If extending a plugin with custom highlights, copy the pattern used in `plugins/editor/nvim-tree/init.lua` (wrapping in `require('utils.ui').catppuccin(...)`).

Keep responses focused: cite specific files, reuse helpers, and preserve lazy-loading semantics.
