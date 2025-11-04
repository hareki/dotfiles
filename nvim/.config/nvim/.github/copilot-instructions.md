## AI Agent Guide (2025-11)

Goal: Extend this Neovim config while preserving its lazy-loading graph, shared layout primitives, and fork-friendly structure.

1. Boot chain: `init.lua` enables `vim.loader` then pulls `configs/{globals,options,autocmds,usercmds,keymaps,lazy}`—add runtime behavior inside plugin specs or events, not in these boot files.
2. Lazy hub: `lua/configs/lazy/init.lua` imports feature folders in the fixed order `ui → ai → coding → editor → formatting → lsp → treesitter`; register new areas by creating `plugins/<area>/init.lua` and adding `{ import = 'plugins.<area>' }` in that slot.
3. Plugin spec pattern: each `lua/plugins/**.lua` returns a table (repo, lazy triggers, opts/config callbacks). Keep shared state in sibling `utils.lua` modules rather than globals.
4. Fork ethos: many specs point to `hareki/*` forks that expose layout hooks; keep custom APIs intact and upstream parity by matching the minimal-diff style already in the repo.
5. Layout + sizing: reuse tokens from `configs/size.lua` (`popup`, `side_panel`, `side_preview` in `sm|md|lg|full|input` variants) via helpers in `utils/ui.lua` (`popup_config`, `computed_size`, `telescope_layout`). Never hard-code dimensions.
6. Float UX contract: Tab toggles focus and `<C-t>` switches side-panel mode across pickers (`plugins/ui/snacks`, Telescope, `plugins/editor/nvim-tree`). Follow those helpers when adding new floats.
7. Palette tweaks: theme overrides live in Catppuccin spec (`plugins/ui/catppuccin.nvim.lua`). Inject extra highlights with `require('utils.ui').catppuccin(function(palette) ... end)` before the target plugin loads.
8. Keymaps: global bindings declared in `configs/keymaps.lua` with CMOS Title Case `desc`. Preserve custom motions (`yy` trimming, `dd` trimming + blackhole). For diagnostic jumps, copy the existing `diagnostic_goto` helper pattern.
9. Notifications & progress: use `utils/notifier.lua` and `utils/progress.lua`; avoid direct `vim.notify` to keep Catppuccin styling consistent.
10. Formatting pipeline: `<A-s>` triggers `utils/formatters/async_style_enforcer.lua` (Conform + lint). Extend the pipeline inside that module instead of introducing new commands or autocommands.
11. Completion & AI: `plugins/coding/blink.cmp.lua` registers completion kinds via `register_kind`, and `plugins/ai/copilot.lua` caps Copilot suggestions at 3. Mirror those helpers to add more kinds or providers.
12. Snippets live in `snippets/` (language JSON + `*-shared.json`). Keep bodies editor-agnostic and follow existing naming.
13. Trees & side panels: `plugins/editor/nvim-tree/` handles float vs docked modes through shared size helpers and state modules—extend there instead of rewriting window logic.
14. Highlight hygiene: create new groups or extend plugin-specific ones; avoid clobbering Catppuccin defaults without explaining the intent in the spec.
15. Cross-cutting changes: if you touch layout math or UI helpers, grep for `popup_config`, `telescope_layout`, and `side_panel` to audit downstream effects across Snacks, Telescope, tree, and custom floats.
16. Validation loop: after meaningful edits run `:Lazy sync`, `:Lazy profile` (for regressions), `:checkhealth`, and sanity-check key flows (formatting, pickers, tree focus) while watching `:messages`.
17. Styling workflow: format Lua with `stylua lua` (config in `.stylua.toml`), keep single quotes, trailing commas, and EmmyLua annotations on public helpers.
18. Quick spec scaffold for reference:

```lua
return {
	'author/plugin',
	event = 'VeryLazy',
	ops = function(_, opts) return opts end,
	config = function(_, opts) require('plugin').setup(opts) end,
}
```

19. When unsure, mirror established patterns—check sibling specs under `plugins/editor` or `plugins/coding` before inventing new abstractions.

Feedback welcome: if any workflow (layout tokens, forks, formatting) needs more detail, call it out so we can iterate.
