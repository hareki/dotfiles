# AGENTS.md

This file provides guidance to AI coding agents (e.g. Claude Code) when working with code in this repository.

## Overview

Personal Neovim configuration using **lazy.nvim** plugin manager. Targets Neovim 0.12+ with native LSP support.

## LuaLS Diagnostics Caveat

The LuaLS diagnostics surfaced to you will often report `undefined-global` for the project globals documented in the [Globals](#globals-luaconfigglobalslua) section, as well as for plugin-provided globals (e.g. `Snacks`). **[VERY IMPORTANT] These are false positives, ignore these warnings entirely.**

## Code Style

- **Formatter**: stylua with 100-char lines, 2-space indent, single quotes, and always-parenthesized calls (see `.stylua.toml`)
- **LuaLS annotations**: `--- @class`, `--- @param`, `--- @return`, `--- @alias` for public APIs
- **LuaLS class names**: `@class` names mirror the module path (`utils.notifier`, `config.keymap-registry`, `utils.ui.layout`), with aliases namespaced under it (`utils.notifier.Message`). Exception: `utils/ui/integrations/*` modules name their class after the `UI` accessor they are exposed as: `utils.ui.statusline` in `integrations/lualine-nvim.lua`, `utils.ui.catppuccin`, `utils.ui.which_key`. Plugin modules mirror the tier path with the plugin dir's `-nvim`/`-lua` suffix dropped; unlike augroups, `features/` classes keep the `features.` prefix (`core/snacks-nvim/utils/image.lua` => `core.snacks.utils.image`, `chrome/lualine-nvim/utils.lua` => `chrome.lualine.utils`, `features/git/gitsigns-nvim/utils.lua` => `features.git.gitsigns.utils`, `features/navigation/nvim-tree-lua/utils.lua` => `features.navigation.nvim-tree.utils`)
- **Requires**: always assign to a local before use — `local x = require('y')` then `x.method()`, never `require('y').method()`
- **String formatting**: use `string.format(...)`, never the method form `('...'):format(...)`
- **Keymaps**: always use `vim.keymap.set()` with `<cmd>...<cr>` strings — never structured `vim.cmd` API. Fall back to function callbacks only when runtime values or multi-statement logic are needed. Always include `desc` in CMOS 18 title case ("Find Files", "Go to Definition"). CMOS 18 title case (rule 8.160): capitalize the first and last words and all major words; lowercase only articles (a, an, the), coordinating conjunctions (and, but, or, nor, for), `to` and `as`, and prepositions of **four or fewer letters** (in, of, on, at, by, with, from, into, over). Prepositions of **five or more letters are capitalized** ("Toggle Fold Under Cursor", "Insert Newline After Cursor", "Add Empty Line Above Cursor" — Under, After, Before, Above, Below, Between, Within, Through, Without). Note this differs from CMOS 17, which lowercased all prepositions regardless of length
- **Icons**: always import from `config/icons.lua` via the `Conf.icons` global — never hardcode icon strings
- **File/dir names**: all file and directory names use `kebab-case`. Name a plugin's spec file/dir after its GitHub repo name (the part after `/`), with **every `.` replaced by `-`**, applied identically to single-file specs and directories (`noice.nvim` => `noice-nvim.lua`, `telescope.nvim` => `telescope-nvim/`, `mini.ai` => `mini-ai/`, `nvim-colorizer.lua` => `nvim-colorizer-lua.lua`, `nvim-tree.lua` => `nvim-tree-lua/`). Exception: when the repo name alone is meaninglessly generic, prefix the author instead (`catppuccin/nvim` becomes `catppuccin-nvim.lua`). User helper modules (under `lua/utils/`, `lua/config/`, etc.) are **also `kebab-case`** (`utils/notifier.lua`, `utils/lazy-require.lua`, `utils/project-config.lua`, `config/keymap-registry.lua`, `utils/style-enforcers/`); multi-word names use hyphens, never underscores. Every name stays dot-free because Lua `require` treats a literal `.` as a path separator; hyphens are valid in both `require()` strings and LuaLS `@class`/`@field`/`@type` names, so when renaming a module update its `require()` paths and those annotations together. **Keep the exact name** for 3rd-party-required files (`lazy-lock.json`, `snippets/package.json`) and for LSP server config files whose basename must equal the server id (`core/lsp/nvim-lspconfig/lsp/lua_ls.lua`, `typos_lsp.lua`). Local Lua variable/function identifiers keep their `snake_case` (they are not filenames); augroup name string literals use `kebab-case` per the **Augroups** convention below.
- **Comment spacing**: always put a space between the comment marker and content — `-- x` not `--x`, `--- @param` not `---@param`. Applies to both inline comments (`--`) and LuaLS annotations (`---`). Never touch `--` inside string literals or `--[[` block markers.
- **Augroups**: `vim.api.nvim_create_augroup` names use a dotted module-path prefix with `kebab-case` segments — `<tier-or-domain>.<plugin>.<purpose>`. Core/chrome plugins use the tier (`core.snacks.hover-image`, `chrome.lualine.buffer-status-cache`); the LSP layer adds an `lsp` sub-tier with the server id or plugin as the next segment (`core.lsp.eslint.attach`, `core.lsp.nvim-lspconfig.attach-keymaps`); features plugins use the domain name directly, dropping the `features.` prefix (`git.git-conflict.keymaps`, `navigation.nvim-tree.preview`); helpers under `lua/utils/` use the `utils.` prefix (`utils.hl-at-cursor.popup-<win>`); config-level autocmds use the `config.autocmds.` prefix (`config.autocmds.checktime`). For dynamic suffixes, concatenate after a hyphen: `'utils.hl-at-cursor.popup-' .. win`

## Commands

- **Format**: `stylua .` (check only: `stylua --check .`) — installed via mise-en-place, on `$PATH`
- No test suite or build system — this is a personal Neovim config, not a library

## Architecture

### Boot Order (`init.lua`)

`vim.loader.enable` => `config.globals` => `config.options` => `config.filetypes` => `config.autocmds` => `config.lazy` (`config.usercmds` and `config.keymaps` are deferred to `User VeryLazy`)

### Plugin Tiers (`lua/`)

- `core/`: infrastructure (theme, icons, snacks, sessions, treesitter, and the LSP layer in `core/lsp/`)
  - Load: catppuccin, snacks.nvim and auto-session are eager (`lazy=false`, `priority=CORE(1000)`); the rest load on events (`BufReadPost`/`BufNewFile` for treesitter; `VeryLazy`, `LspAttach` or `ft` for the LSP layer), on first `require()` (mini.icons), or as a dependency (nvim-treesitter-textobjects, via mini.ai)
- `chrome/`: visual layer (statusline, winbar, scrollbar, notifications, folds, decorations, which-key)
  - Load: only noice.nvim is eager (`lazy=false`, `priority=CHROME(900)`); the rest use `event='VeryLazy'`, buffer events, `ft` or `keys`
- `features/{domain}/`: domain features in 8 groups (navigation, completion, git, editing, search, diagnostics, formatting, ai)
  - Load: on demand via `keys`, `cmd`, `ft` or `event` (mostly `VeryLazy`; blink.cmp uses `InsertEnter`/`CmdlineEnter`), or a `require()` from another module (e.g. conform.nvim via `utils/style-enforcers/`)

`priority` only orders eager plugins, so lazy specs leave it unset.

Import order in `config/lazy/init.lua`: `core` **must be first**, followed by `core.lsp` (lazy.nvim's `import` only descends into subdirectories that have an `init.lua`, so `core/lsp/` needs its own entry). All plugins lazy by default (`defaults.lazy=true`).

### Globals (`lua/config/globals.lua`)

Six globals available everywhere (five set in `globals.lua`, one by its plugin). `Conf` groups the constant config tables; only `Notifier` is a lazy proxy, `UI` is required directly:

- `Defer` (`utils.lazy-require`): `Defer.on_index(path)` defers the `require` until the first field access, `Defer.on_exported_call(path)` until the first call of an exported function
- `Notifier` (lazy proxy => `utils.notifier`): `Notifier.info('msg')`, `Notifier.warn('msg', { title = 'T' })`, `Notifier.error()`
- `Conf` (`config`; `config/init.lua` assembles the `config.*` tables): `Conf.icons` (never hardcode icons), `Conf.filetypes` (`JS`, `JSX`, `CSS`, `MARKDOWN`, …), `Conf.priority` (`CORE=1000`, `CHROME=900`, `FEATURE=800`), `Conf.picker`, `Conf.size`, `Conf.cmp` (from `config/completion.lua`)
- `UI` (`utils.ui`, direct require):
  - Spec registration: `UI.catppuccin(fn, plugin_name?)`, `UI.which_key(spec)`
  - Helpers: `UI.layout.popup()` / `UI.layout.popup_fn()` / `UI.layout.side_size()`, `UI.color.blend_hex()`, `UI.pill.virt_text()`, `UI.cursorline.set_cursorline()`
  - Integration helpers: `UI.catppuccin.get_palette('ext')`, `UI.statusline.enabled()` / `UI.statusline.refresh()`
- `Project` (`utils.project-config`): `Project.linter` (`'eslint'` default, or `'oxlint'`) and `Project.formatter` (`'prettier'` default, or `'oxfmt'`), overridden per project by `.neovimrc.json` in the initial cwd
- `Snacks` (set by snacks.nvim at runtime): `Snacks.picker.*`, `Snacks.terminal.*`, etc.

## Plugin Spec Conventions

### Key Order

`'author/repo'` => `enabled`/`cond`/`name`/`branch`/`version`/`build`/`main` => `lazy`/`priority` => `cmd`/`event`/`ft` => `dependencies` => `init` => `keys` => `opts`/`opts_extend` => `config`

### Opts

Wrap `opts` in a function (`opts = function() return { ... } end`) only when the plugin is lazy-loaded AND opts is non-empty. lazy.nvim parses every spec file eagerly at startup to learn each plugin's load triggers (`ft`/`event`/`keys`/etc.), so for a lazy-loaded plugin the function defers the table's construction until the plugin actually loads. A plugin counts as NOT lazy-loaded when it has `lazy = false` or unfiltered buffer/window events (e.g. `BufReadPost`/`BufNewFile`): it loads unconditionally at startup, wrapping defers nothing, so its static opts must stay a plain table. Keep the function form for an eager plugin only when the body needs additional logic (requires, computed locals); converting such a body to a plain table would also shift evaluation to spec-parse time, before plugin rtp paths exist. Empty `opts = {}` stays plain everywhere. The same static-vs-logic split applies to the LSP server-loader files' `opts` (see LSP Setup below), where the loader resolves `opts` immediately either way.

### Keys

`keys` defaults to a plain table: lazy.nvim resolves `keys` eagerly at startup to register the load triggers, so wrapping a static list in a function (`keys = function() return { ... } end`) defers nothing, unlike the Opts rule above. Entries whose callbacks close over parse-time locals or `Defer` proxies, or `require()` inside the callback body, are still static and belong in the plain table. Keep the function form only when the keys body itself needs logic at resolve time: building entries programmatically (`features/navigation/harpoon.lua` loops over pin slots) or a body-level local shared by several entries (`features/search/nvim-hlslens/init.lua` requires its utils module once).

### Return Convention

```lua
-- Single spec (majority):
return { 'author/plugin', keys = { ... }, opts = { ... } }

-- List with catppuccin/which-key registration (always in this order):
return { UI.catppuccin(function(...) ... end, 'plugin'), UI.which_key({ ... }), { 'author/plugin', opts = ... } }
```

`UI.catppuccin`'s optional second argument is the lazy.nvim plugin name: the highlight callback then runs when that plugin loads (applied with `nvim_set_hl`, re-applied on `ColorScheme`) instead of merging into catppuccin's `custom_highlights` at startup. Pass it for plugins loaded by `event`/`ft`/`keys`/`cmd`/`require()`; omit it for `lazy=false` and `BufRead*`-triggered plugins, and when the callback recolors built-in groups used before the plugin loads (nvim-hlslens recolors the search groups).

### Directory Plugins

For plugins with state or large configs: `init.lua` (specs) + `utils.lua` (helpers, holding `M.state = {}` when the plugin keeps state) + optional `config/` sub-modules. See `nvim-tree-lua/` (state) and `blink-cmp/` (`config/` split); larger plugins grow `utils.lua` into a `utils/` directory (`core/snacks-nvim/`).

### Popup Sizing

Never hardcode dimensions; size floats through `UI.layout` (`utils/ui/layout.lua`). `with_border=true` adds 2 cells per dimension for consumers whose size includes the border.

- `UI.layout.popup(size, with_border)`: centered window config for a `Conf.size.popup` preset (`full`, `lg`, `vertical_md`, `vertical_sm`, `md`, `sm`) or `'input'`
- `UI.layout.popup_fn(size, with_border)`: the same with function-valued fields, resolved at window-open time so popups stay sized and centered after terminal resizes. Use it when the consumer accepts callables (Snacks does for `width`/`height`/`col`/`row`, but not `max_width`/`max_height`, so leave those unset)
- `UI.layout.side_size(category, variant, with_border)`: side panels (`side_panel`: `sm`/`md`/`lg`) and side previews (`side_preview`: `md`)
- `UI.layout.telescope(size)`: Telescope `layout_config`

**Gotcha**: Telescope always needs `with_border=true` (`UI.layout.telescope` passes it); nvim-tree always needs `false`; Snacks varies by variant: `false` for `input`, `full`, `lg`, `vertical_md` and `true` for the bordered `sm` / `lg_border`. Exception: content-sized, cursor-anchored tooltips (e.g. `utils/hl-at-cursor.lua`) size themselves from their content, since `UI.layout` only produces centered preset-sized popups; inline popups (gitsigns, eagle, nvim-notify) cap their height with `Conf.size.inline_popup.MAX_HEIGHT`.

## LSP Setup

Uses Neovim 0.12+ native `vim.lsp.enable()` / `vim.lsp.config()` (not `lspconfig[server].setup()`). Per-server files live at `core/lsp/nvim-lspconfig/lsp/{server}.lua`: **these are NOT lazy.nvim specs and NOT raw `vim.lsp.Config` tables**. Each file returns `{ opts = table|function, setup = function? }`; `nvim-lspconfig/utils/server-loader.lua` walks the directory, calls `vim.lsp.config(name, opts)`, then invokes `setup()` if present. General LSP keymaps live in `nvim-lspconfig/init.lua`, not server files.

The enabled servers are the `servers` list in `nvim-lspconfig/init.lua`: `Project.linter` picks `eslint` or `oxlint`, and `oxfmt` is added when `Project.formatter` is `'oxfmt'`. `load_all()` and `vim.lsp.enable(servers)` run in a 75 ms `vim.defer_fn` so the buffer renders first. A server needs a `lsp/{server}.lua` file only to override nvim-lspconfig's defaults (`marksman`, `taplo`, `css_variables`, `stylua` and `astro` run on the defaults).

Server-specific `LspAttach` autocmds use an early-return guard on client name (see `lsp/eslint.lua`, `lsp/vtsls.lua`). `Snacks.util.lsp.on({ name = '<server>' }, fn)` already fires once per matching client, so call it at the top level of `setup()`, never inside an `LspAttach` callback, which leaks watchers.

**Gotcha**: nvim-lspconfig uses `event='VeryLazy'` instead of `LazyFile` to avoid directory file-type detection issues.

## Forks

22 minimal-diff plugin forks by `hareki` (list them with `rg -o --no-filename "'hareki/[^']+'" lua | sort -u`), plus 2 parser forks (`tree-sitter-glimmer`, `tree-sitter-scss`) registered in `core/nvim-treesitter.lua`. Updated via [wei/pull](https://github.com/wei/pull) (`.github/pull.yml`), except `eagle.nvim` and `tree-sitter-scss`, which have none.
