# AGENTS.md

## Overview

Personal Neovim 0.12+ configuration using the **lazy.nvim** plugin manager.

## LuaLS Diagnostics Caveat

The LuaLS diagnostics surfaced to you come from Claude Code's own server. It roots at the session's working directory when it starts (on the first Lua file touched), and only when rooted at the dotfiles root does it read Neovim's runtime and plugin libraries from the root `.luarc.json`. When it flags `vim` itself as an undefined global, it runs without them (rooted in `nvim/.config/nvim`, or on a scratch file outside the repo), and its `undefined-global` reports (`vim`, `Snacks`, and in scratch files the [Globals](#globals-luaconfigglobalslua) below), `undefined-doc-name` and `undefined-field` on `vim` or plugin names and types are **false positives**: ignore them.

## Code Style

- **LuaLS annotations**: `--- @class`, `--- @param`, `--- @return`, `--- @alias` for public APIs
- **LuaLS class names**: `@class` names mirror the module's namespace, its `require` path with each plugin dir's `-nvim`/`-lua` suffix dropped (`config/keymap-registry.lua` => `config.keymap-registry`, `features/search/snacks-nvim/utils/formatters.lua` => `features.search.snacks.utils.formatters`, `features/navigation/nvim-tree-lua/utils.lua` => `features.navigation.nvim-tree.utils`), with aliases nested under it (`utils.notifier.Message`); renaming a module renames its class and every `require()` path and annotation that names it. Exception: `utils/ui/integrations/*` classes take their `UI` accessor's name (`utils.ui.statusline` in `integrations/lualine-nvim.lua`, `utils.ui.which_key`)
- **Requires**: always assign to a local before use: `local x = require('y')` then `x.method()`, never `require('y').method()`
- **String formatting**: use `string.format(...)`, never the method form `('...'):format(...)`
- **Keymaps**: define them with `vim.keymap.set()` or a spec `keys` entry, using `<cmd>...<cr>` strings rather than the structured `vim.cmd` API; fall back to a function only for runtime values or multi-statement logic. Every keymap gets a `desc` in CMOS 18 title case (rule 8.160): capitalize the first, last and all major words; lowercase only articles (a, an, the), coordinating conjunctions (and, but, or, nor, for), `to`, `as`, and prepositions of **four or fewer letters** (in, of, on, at, by, with, from, into, over), as in "Go to Definition". Prepositions of **five or more letters are capitalized** (Under, After, Before, Above, Below, Between, Within, Through, Without), as in "Toggle Fold Under Cursor"; this differs from CMOS 17, which lowercased all prepositions regardless of length
- **Icons**: always import from `config/icons.lua` via the `Conf.icons` global, never hardcode icon strings
- **File/dir names**: all file and directory names use `kebab-case` and stay dot-free, since Lua `require` treats a literal `.` as a path separator. Name a plugin's spec file/dir after its GitHub repo name (the part after `/`), with **every `.` replaced by `-`** (`noice.nvim` => `noice-nvim.lua`, `snacks.nvim` => `snacks-nvim/`, `mini.ai` => `mini-ai/`, `nvim-colorizer.lua` => `nvim-colorizer-lua.lua`, `nvim-tree.lua` => `nvim-tree-lua/`); a split plugin's fragments (see **Split Plugins**) reuse that name in every tier/domain dir (`core/snacks-nvim/`, `features/editing/snacks-nvim.lua`). Exception: when the repo name alone is meaninglessly generic, prefix the author instead (`catppuccin/nvim` becomes `catppuccin-nvim.lua`). **Keep the exact name** for 3rd-party-required files (`lazy-lock.json`, `snippets/package.json`) and for LSP server config files whose basename must equal the server id (`core/lsp/nvim-lspconfig/lsp/lua_ls.lua`, `typos_lsp.lua`).
- **Comment spacing**: a space after the comment marker: `-- x` not `--x`, `--- @param` not `---@param` (leave `--` inside string literals and `--[[` block markers alone).
- **Augroups**: the owning plugin's or helper module's namespace (as in **LuaLS class names**) plus a `kebab-case` purpose (`chrome.lualine.buffer-status-cache` from `chrome/lualine-nvim/components/buffer-status.lua`, `features.git.git-conflict.keymaps`, `core.lsp.nvim-lspconfig.vtsls-attach` from `lsp/vtsls.lua`); config-level autocmds use `config.autocmds.<purpose>`. For dynamic suffixes, concatenate after a hyphen: `'utils.hl-at-cursor.popup-' .. win`

## Commands

- **Format**: run `stylua .` after editing Lua (check only: `stylua --check .`; config in `.stylua.toml`), installed via mise-en-place, on `$PATH`
- No test suite or build system

## Architecture

### Plugin Tiers (`lua/`)

- `core/`: infrastructure (theme, icons, snacks, sessions, treesitter, and the LSP layer in `core/lsp/`)
- `chrome/`: visual layer (statusline, winbar, scrollbar, notifications, folds, decorations, which-key)
- `features/{domain}/`: domain features (navigation, completion, git, editing, search, diagnostics, formatting, ai, preview)

Plugins are lazy by default (`defaults.lazy = true`). Only catppuccin, snacks.nvim, auto-session (`priority = Conf.priority.CORE`) and noice.nvim (`Conf.priority.CHROME`) are eager (`lazy = false`); `priority` only orders those, so lazy specs leave it unset. The rest load on `event` (mostly `VeryLazy`), `ft`, `keys` or `cmd`, on first `require()` (mini.icons; conform.nvim from `utils/style-enforcers/`), or as a dependency (nvim-treesitter-textobjects via mini.ai).

`config/lazy/init.lua` imports `core` (**must stay first**), `core.lsp`, `chrome`, then each `features.{domain}`: lazy.nvim's `import` loads only direct `*.lua` files and `*/init.lua` modules, so `core/lsp/` and every new domain dir need their own entry.

### Globals (`lua/config/globals.lua`)

- `Defer` (`utils.lazy-require`): `Defer.on_index(path)` defers the `require` until the first field access, `Defer.on_exported_call(path)` until the first call of an exported function
- `Notifier` (lazy proxy => `utils.notifier`): `Notifier.info('msg')`, `Notifier.warn('msg', { title = 'T' })`, `Notifier.error()`
- `Conf` (`config`; `config/init.lua` assembles the `config.*` tables): `Conf.icons`, `Conf.filetypes` (`JS`, `JSX`, `CSS`, `MARKDOWN`, …), `Conf.priority`, `Conf.picker`, `Conf.size`, `Conf.cmp` (from `config/completion.lua`)
- `UI` (`utils.ui`, direct require):
  - Spec registration: `UI.catppuccin(fn, plugin_name?)`, `UI.which_key({ specs?, rules?, triggers? })`
  - Helpers: `UI.layout.*` (see **Popup Sizing**), `UI.color.blend_hex()`, `UI.pill.virt_text()`, `UI.cursorline.set_cursorline()`, `UI.mode.name()` / `UI.mode.colors` (the per-mode palette shared by lualine's mode pill and modicator.nvim)
  - Integration helpers: `UI.catppuccin.get_palette('ext')`, `UI.statusline.enabled()` / `UI.statusline.refresh()`
- `Project` (`utils.project-config`): `Project.linter` (`'eslint'` default, or `'oxlint'`) and `Project.formatter` (`'prettier'` default, or `'oxfmt'`), overridden per project by `.neovimrc.json` in the initial cwd
- `Snacks` (set by snacks.nvim at runtime): `Snacks.picker.*`, `Snacks.terminal.*`, etc.

## Plugin Spec Conventions

### Key Order

`'author/repo'` => `enabled`/`cond`/`name`/`branch`/`version`/`build`/`main` => `lazy`/`priority` => `cmd`/`event`/`ft` => `dependencies` => `init` => `keys` => `opts`/`opts_extend` => `config`

### Opts and Keys

Make `opts` or `keys` a function (`opts = function() return { ... } end`) exactly when the function buys deferral or body-level logic; otherwise it stays a plain table, including an empty `opts = {}`:

- **Deferral** comes only to a lazy-loaded plugin's `opts`: lazy.nvim parses every spec file at startup to learn load triggers, and the function builds the table only when the plugin loads. `keys` and the `opts` of plugins that load at startup anyway (`lazy = false`, or unfiltered buffer/window events such as `BufReadPost`/`BufNewFile`) resolve right away, so a function defers nothing there
- **Body-level logic** means requires, computed locals or programmatically built entries in the function body itself (`features/navigation/harpoon/init.lua` loops over pin slots, `features/search/nvim-hlslens/init.lua` shares one utils local across entries); for a plugin that loads at startup, the function also keeps those requires out of spec-parse time, before plugin rtp paths exist. Callbacks that close over parse-time locals or `Defer` proxies, or `require()` inside their own body, are not body-level logic

### Return Convention

```lua
-- Single spec:
return { 'author/plugin', keys = { ... }, opts = { ... } }

-- List with catppuccin/which-key registration (always in this order):
return { UI.catppuccin(function(...) ... end, 'plugin'), UI.which_key({ ... }), { 'author/plugin', opts = ... } }
```

`UI.catppuccin`'s optional second argument is the lazy.nvim plugin name: the highlight callback then runs when that plugin loads (mechanism in `utils/ui/integrations/catppuccin-nvim.lua`) instead of merging into catppuccin's `custom_highlights` at startup. Pass it for plugins loaded by `event`/`ft`/`keys`/`cmd`/`require()`; omit it for `lazy=false` and `BufRead*`-triggered plugins, and when the callback recolors built-in groups used before the plugin loads (nvim-hlslens recolors the search groups). The plugin must have its own `opts` or `config`: the `opts` fragment the helper adds to it would otherwise make lazy.nvim start calling its `setup()`.

### Directory Plugins

Give a plugin the directory form once it has state or more than a few lines of helper logic (wrappers, monkey-patches), keeping its spec file to the lazy.nvim tables and tiny locals such as a desc `prefix`: `init.lua` (specs) + `utils.lua` (helpers, holding `M.state = {}` when the plugin keeps state) + optional `config/` sub-modules. See `nvim-tree-lua/` (state), `live-preview-nvim/` (wrappers) and `blink-cmp/` (`config/` split); larger plugins grow `utils.lua` into a `utils/` directory (`features/search/snacks-nvim/`).

### Split Plugins

A plugin that bundles unrelated features (snacks.nvim) is split into one spec fragment per feature, each filed where a standalone plugin doing that job would live; lazy.nvim merges fragments that share a plugin name. The base fragment sits in the tier that owns loading (`core/snacks-nvim/`) and alone carries `'author/repo'`, `lazy`/`priority`, the opts several features share and features with no domain of their own (the floating terminal).

Every other fragment names the plugin bare (`'snacks.nvim'`) and holds only its feature's `keys`, `opts` (including the module's `styles.<module>` entry) and helpers (`fd snacks-nvim lua` lists every fragment). A new module's config joins the fragment of the domain it serves, picker keymaps included (`<leader>fgb` lives in the git fragment). Helpers stay with the domain that owns them and other domains require them from there (harpoon's picker uses the search fragment's formatters); `core/snacks-nvim/utils.lua` holds only helpers no single domain owns (the full-screen panel juggling shared by lazygit and the coding agent).

- Fragments use plain-table `keys`/`opts`, overriding **Opts and Keys**, and compute anything that needs logic at parse time (`Defer` proxies and locals at the file top, or inline like the fold-keys fragment's `vim.tbl_map` in `features/search/snacks-nvim/init.lua`): lazy.nvim passes a function-valued `keys`/`opts` only the value merged from fragments imported before it, and a non-nil return replaces that value, silently dropping their entries. lazy.nvim concatenates `keys` and deep-merges `opts` in import order (lists inside `opts` are replaced, not merged)
- `init` and `config` resolve to the last fragment that defines them, silently shadowing the rest, so fragments leave both unset. Startup code goes in an extra opts-only fragment whose function `opts` runs it and returns nil, which lazy.nvim resolves right before the plugin's `setup()` (the lazygit tracker in `features/git/snacks-nvim/init.lua`)

## Popup Sizing

Size floats through `UI.layout` (`utils/ui/layout.lua`, whose annotations document each helper), never hardcoded dimensions; only cursor-anchored tooltips (e.g. `utils/hl-at-cursor.lua`) size themselves from their content, since `UI.layout` has no cursor-relative placement.

- Snacks picker layouts take `picker_fn`, since their size counts the borders of the windows they draw; windows (`Snacks.win` styles, `nvim_open_win`, nvim-tree) take `popup`/`popup_fn`
- Prefer the function-valued helpers (`popup_fn`, `picker_fn`, the `inline_max_height`/`inline_max_width` caps) wherever the consumer accepts callables, so sizes follow terminal resizes; Snacks accepts them for `width`/`height`/`col`/`row`, not `max_width`/`max_height`

## LSP Setup

Uses native `vim.lsp.enable()` / `vim.lsp.config()` (not `lspconfig[server].setup()`). Each `core/lsp/nvim-lspconfig/lsp/{server}.lua` returns `{ opts = table|function, setup = function? }`, **not a lazy.nvim spec or a raw `vim.lsp.Config`**: `nvim-lspconfig/utils/server-loader.lua` loads every file, resolving `opts` right away (so it stays a plain table unless it needs logic), then calls `vim.lsp.config(name, opts)` and `setup()` if present. General LSP keymaps live in `nvim-lspconfig/init.lua`, not server files.

Enable a server in the `servers` list in `nvim-lspconfig/init.lua`; add a `lsp/{server}.lua` only to override nvim-lspconfig's defaults. Servers that drive style-enforcer steps (`eslint`, `oxlint`, `oxfmt`) are also registered in `utils/style-enforcers/init.lua`, where `client = '<server>'` limits each step to buffers that server is attached to.

Server-specific `LspAttach` autocmds use an early-return guard on client name (see `lsp/vtsls.lua`).

## Forks

Minimal-diff plugin forks by `hareki` (list them with `rg -o --no-filename "'hareki/[^']+'" lua | sort -u`), plus the parser forks `tree-sitter-glimmer` and `tree-sitter-scss` registered in `core/nvim-treesitter.lua`. Updated via [wei/pull](https://github.com/wei/pull) (`.github/pull.yml`), except `eagle.nvim` and `tree-sitter-scss`, which have none.
