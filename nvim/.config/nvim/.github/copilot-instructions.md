## AI Agent Guide (Concise)

Goal: Safely extend / refactor this Neovim config by following its established architecture, sizing/layout abstractions, and plugin spec conventions.

1. Boot Flow: `init.lua` (Lua loader cache) -> `configs/{globals,options,autocmds,usercmds,keymaps,lazy}`. Do not insert other startup side‑effects; add runtime logic via plugin events.
2. Plugin Specs: Central hub `lua/configs/lazy/init.lua` imports feature folders (`plugins/{ui,ai,coding,editor,formatting,lsp,treesitter}`). Add new area → create folder + add `{ import = 'plugins.<area>' }` in order (UI first for palette helpers).
3. Reuse Helpers: Layout + palette in `configs/size.lua` & `utils/ui.lua`; notifications `utils/notifier.lua`; formatting pipeline `utils/formatters/async_style_enforcer.lua`; completion kinds `plugins/coding/blink.cmp.lua`; tree layout logic `plugins/editor/nvim-tree/`.
4. Sizing: Never hard‑code widths/heights. Use size tokens `sm|md|lg|full|input` via `utils.ui.popup_config()` / `telescope_layout()` / values from `configs/size.lua` (`side_panel`, `side_preview`).
5. Theme Overrides: Inject Catppuccin adjustments early with `require('utils.ui').catppuccin(function(palette) return { Group = { fg = palette.text } } end)` placed in a spec that loads before the target plugin.
6. Spec Pattern: Each file returns a table: `{ 'repo/name', event=..., opts=function(_,opts) return opts end, config=function(_,opts) require('module').setup(opts) end }`. Avoid mutating unrelated globals; isolate state in a local `utils.lua` if shared.
7. Keymaps: Global maps live in `configs/keymaps.lua`. Always include `desc`. Preserve custom editing motions: `yy` (trim yank), `dd` (trim + blackhole). Diagnostic jumps follow `diagnostic_goto(next, severity)`—copy that form for new severity filters.
8. Formatting Workflow: `<A-s>` runs async style enforcer (format + lint). Extend by adding steps inside `utils/formatters/async_style_enforcer.lua` instead of creating parallel commands.
9. Completion & AI: Blink.cmp kinds registered via helper; Copilot limited to 3 items (`copilot_max_items`). Add new kinds with the same `register_kind()` pattern.
10. Snippets: `snippets/` split into language + `*-shared.json`. Follow naming; don’t embed editor‑specific commands inside snippet bodies.
11. Performance: Lazy load by default. Only set `lazy=false, priority=1000` for early theme or global patches. Core disabled built‑ins listed in `configs/lazy/init.lua`; keep aligned when adding plugins.
12. Floating Panels & Trees: Nvim-tree sizing + dual (float/side) behavior relies on its `state` + shared size helpers—never replace with fixed `vim.api.nvim_open_win` args directly.
13. Notifications: Use `require('utils.notifier').info|warn|error` (tuple highlighting) instead of `vim.notify` to ensure style & palette consistency.
14. Highlight Additions: Prefer creating new groups; avoid silently overriding core Catppuccin groups unless intentionally theming.
15. Refactors: Changing sizing math or UI helpers? Audit usages (`grep popup_config`, `telescope_layout`, `side_panel`). Changes cascade widely.
16. Validation: After changes run `:Lazy sync`, `:checkhealth`, exercise key features (formatting, telescope, tree, completion), and inspect `:messages` for stack traces.
17. Common Pitfalls: (a) Forgeting new import in lazy spec (plugin never loads); (b) hard‑coded window dimensions; (c) overriding `<Space>` leader; (d) direct `vim.notify`; (e) highlight name collisions.
18. Style: Use Stylua rules (see `.stylua.toml` if present). Keep EmmyLua annotations for public helpers (`---@param`, `---@class`). Use trailing commas in multiline tables like existing specs.
19. Quick Example (plugin spec skeleton):

```lua
return {
	'author/plugin',
	event = 'VeryLazy',
	opts = function(_, opts) return opts end,
	config = function(_, opts) require('plugin').setup(opts) end,
}
```

20. When Unsure: Search existing plugin patterns first (`plugins/editor/`, `plugins/coding/`). Mirror established structure instead of inventing new abstractions.

Feedback Welcome: If any area feels under‑specified (e.g. completion kinds, layout tokens, formatting pipeline), ask and we can expand that section.
