# AGENTS.md

## Overview

Personal Neovim 0.12+ configuration using the lazy.nvim plugin manager.

## LuaLS Diagnostics

The LuaLS diagnostics surfaced to you come from Claude Code's server, run by the `nvim-lua-lsp@dotfiles` plugin (`.claude/marketplace/.claude-plugin/marketplace.json`), which this project's and the dotfiles root's `.claude/settings.json` enable in place of the official `lua-lsp`. Its `settings` give it LuaJIT, Neovim's runtime and the lazy plugin dir wherever it roots, so its reports are real, except in scratch files outside the repo, where it flags the [Globals](#globals-luaconfigglobalslua) below as undefined. When it flags `vim` itself as an undefined global, the session runs the official `lua-lsp` instead (started outside the dotfiles), and its `undefined-global`, `undefined-doc-name` and `undefined-field` reports on `vim` or plugin names and types are **false positives**: ignore them.

## Code Style

- **LuaLS annotations**: `--- @class`, `--- @param`, `--- @return`, `--- @alias` for public APIs
- **LuaLS class names**: a module's `@class` name is its `require` path, verbatim (`config/builtin-keymaps.lua` => `config.builtin-keymaps`, `features/search/snacks-nvim/sources/tabs.lua` => `features.search.snacks-nvim.sources.tabs`, `utils/ui/statusline.lua` => `utils.ui.statusline`), with aliases nested under it (`utils.notifier.Message`); renaming a module renames its class and every `require()` path and annotation that names it
- **Requires**: always assign to a local before use: `local x = require('y')` then `x.method()`, never `require('y').method()`
- **String formatting**: use `string.format(...)`, never the method form `('...'):format(...)`
- **Constants**: a file-level local holding data the file never reassigns or mutates once loaded (lookup tables, lists, config tables, fixed strings and numbers, a spec's desc `PREFIX`) is `UPPER_SNAKE` (`IGNORED_FILETYPES`, `TIMEOUT_MS`); state, requires and proxies, aliases (`local fs = vim.fs`), functions, handles (namespace and augroup ids) and objects (a ringbuf, a scoped notifier) stay `snake_case`
- **Keymaps**: define them with `vim.keymap.set()` or a spec `keys` entry, using `<cmd>...<cr>` strings rather than the structured `vim.cmd` API; fall back to a function only for runtime values or multi-statement logic. Every keymap gets a `desc` in CMOS 18 title case (rule 8.160): capitalize the first, last and all major words; lowercase only articles (a, an, the), coordinating conjunctions (and, but, or, nor, for), `to`, `as`, and prepositions of **four or fewer letters** (in, of, on, at, by, with, from, into, over), as in "Go to Definition". Prepositions of **five or more letters are capitalized** (Under, After, Before, Above, Below, Between, Within, Through, Without), as in "Toggle Fold Under Cursor"; this differs from CMOS 17, which lowercased all prepositions regardless of length
- **Icons**: always import from `config/icons.lua` via the `Conf.icons` global, never hardcode icon strings
- **Notifications**: every notification names its source, which the notification history lists: `local notify = Notifier.scoped('Title')` in a module that notifies twice or more, `{ title = 'Title' }` on a one-off (an untitled one shows as "Notifier")
- **File/dir names**: all file and directory names use `kebab-case` and stay dot-free, since Lua `require` treats a literal `.` as a path separator. Name a plugin's spec file/dir after its GitHub repo name (the part after `/`), with **every `.` replaced by `-`** (`noice.nvim` => `noice-nvim.lua`, `snacks.nvim` => `snacks-nvim/`, `mini.ai` => `mini-ai/`, `nvim-colorizer.lua` => `nvim-colorizer-lua.lua`, `nvim-tree.lua` => `nvim-tree-lua/`); a split plugin's fragments (see **Split Plugins**) reuse that name in every tier/domain dir (`core/snacks-nvim/`, `features/editing/snacks-nvim.lua`). Exception: when the repo name alone is meaninglessly generic, prefix the author instead (`catppuccin/nvim` becomes `catppuccin-nvim.lua`). **Keep the exact name** for 3rd-party-required files (`lazy-lock.json`, `snippets/package.json`) and for LSP server config files whose basename must equal the server id (`core/lsp/nvim-lspconfig/lsp/lua_ls.lua`, `typos_lsp.lua`).
- **Comment spacing**: a space after the comment marker: `-- x` not `--x`, `--- @param` not `---@param` (leave `--` inside string literals and `--[[` block markers alone).
- **Augroups**: the owning plugin's or helper module's namespace (as in **LuaLS class names**) plus a `kebab-case` purpose (`chrome.lualine-nvim.buffer-status-cache` from `chrome/lualine-nvim/components/buffer-status.lua`, `features.git.git-conflict-nvim.conflicted-buffers`, `core.lsp.nvim-lspconfig.utils.typescript.attach-vtsls` from `nvim-lspconfig/utils/typescript.lua`); config-level autocmds use `config.autocmds.<purpose>`. For dynamic suffixes, concatenate after a hyphen: `'utils.popup.link-' .. win`
- **Entry points**: a module that something outside nvim reaches by its path says so in its header, naming the caller and the rule that follows. lazygit's diff renderer dofiles `config/filetypes/init.lua`, `config/filetypes/languages.lua` and `config/treesitter-highlights.lua` under `nvim --clean`, so they read no globals and require no config module; lazygit's `config.yml` and the `tsave` zsh function call `features/git/snacks-nvim/lazygit.lua` and `core/auto-session/utils.lua` through `--remote-expr`, so their paths and function names stay stable (`tests/lazygit.lua` checks config.yml's calls)

## Commands

- **Format**: run `stylua .` after editing Lua (check only: `stylua --check .`; config in `.stylua.toml`), installed via Homebrew, on `$PATH`
- **Test**: `tests/run.sh [words]` runs the test files in `tests/` (all, or those whose name contains a word), each in its own headless nvim booted on the working tree with `VeryLazy` fired. A test file registers its tests through `tests/lib/helpers.lua` and drives modules through the interface their callers use (`tests/popup.lua` is the model)
- **A/B**: `tests/ab.sh [rev]` boots `rev` (default `HEAD`) and the working tree with every plugin loaded and diffs what each config defines: maps (global and per filetype), highlights, autocmds, commands, options, plugin specs and resolved opts, LSP configs, which-key specs and icons, and the modules on the startup path. Two boots of one config dump identically, so every diff row is a change to account for; `NVIM_AB_KEEP=<dir>` keeps both dumps
- One-off probes follow `tests/lib/env.sh`, whose rules each cost a real incident: never override `XDG_DATA_HOME`, never dump the environment, and end a boot with `os.exit`. No build system

## Architecture

### Plugin Tiers (`lua/`)

- `core/`: infrastructure (theme, icons, snacks, sessions, treesitter, and the LSP layer in `core/lsp/`)
- `chrome/`: visual layer (statusline, winbar, scrollbar, notifications, folds, decorations, which-key)
- `features/{domain}/`: domain features (navigation, completion, git, editing, search, diagnostics, formatting, ai, preview)

Plugins are lazy by default (`defaults.lazy = true`). Only catppuccin, snacks.nvim, auto-session (`priority = Conf.priority.CORE`) and noice.nvim are eager (`lazy = false`); `priority` only puts the first three ahead of noice, so lazy specs leave it unset. The rest load on `event` (mostly `VeryLazy`), `ft`, `keys` or `cmd`, on first `require()` (mini.icons; tiny-code-action.nvim from the `<leader>ca` keymap), or as a dependency (nvim-treesitter-textobjects via mini.ai).

`config/lazy/init.lua` imports `core` (**must stay first**), `core.lsp`, `chrome`, then each `features.{domain}`: lazy.nvim's `import` loads only direct `*.lua` files and `*/init.lua` modules, so `core/lsp/` and every new domain dir need their own entry.

### Globals (`lua/config/globals.lua`)

- `Defer` (`utils.lazy-require`): `Defer.on_index(path)` defers the `require` until the first field access, `Defer.on_exported_call(path)` until the first call of an exported function. Every proxy, from `Defer` or from `utils.lazy-require` itself, carries `--- @module '<path>'` on the line above it: otherwise LuaLS sees a plain table, and a misspelled field passes the check to fail on the keypress
- `Notifier` (lazy proxy => `utils.notifier`): `Notifier.info('msg')`, `Notifier.warn('msg', { title = 'T' })`, `Notifier.error()`, the `*_once` variants (once per message per session), and `Notifier.scoped(title)`, which returns the same functions with the title filled in
- `Conf` (`config`; `config/init.lua` assembles the `config.*` tables): `Conf.icons`, `Conf.filetypes` (`JS`, `JSX`, `CSS`, `MARKDOWN`, …), `Conf.priority`, `Conf.zindex` (the float stacking ladder), `Conf.picker`, `Conf.size`, `Conf.cmp` (from `config/completion.lua`)
- `UI` (`utils.ui`, direct require):
  - Spec registration: `UI.catppuccin(fn, plugin_name?)`, `UI.which_key({ specs?, rules?, triggers? })`
  - Helpers: `UI.layout.*` (see **Popup Sizing**), `UI.color.blend_hex()`, `UI.search.is_active()` / `UI.search.clear()` (search highlighting, which Snacks word references give way to), `UI.pill.virt_text()`, `UI.cursorline.follow_focus()` (the cursor line follows the focused window), `UI.mode.name()` / `UI.mode.colors` (the per-mode palette shared by lualine's mode pill and the cursor line number)
  - Integration helpers: `UI.catppuccin.get_palette('ext')`, `UI.statusline.integration` / `UI.statusline.refresh()`
- `Snacks` (set by snacks.nvim at runtime): `Snacks.picker.*`, `Snacks.terminal.*`, etc.

## Plugin Spec Conventions

### Key Order

`'author/repo'` => `enabled`/`cond`/`name`/`branch`/`version`/`build`/`main` => `lazy`/`priority` => `cmd`/`event`/`ft` => `dependencies` => `init` => `keys` => `opts`/`opts_extend` => `config`

### Opts and Keys

Make `opts` or `keys` a function (`opts = function() return { ... } end`) exactly when the function buys deferral or body-level logic; otherwise it stays a plain table, including an empty `opts = {}`:

- **Deferral** comes only to a lazy-loaded plugin's `opts`: lazy.nvim parses every spec file at startup to learn load triggers, and the function builds the table only when the plugin loads. `keys` and the `opts` of plugins that load at startup anyway (`lazy = false`, or unfiltered buffer/window events such as `BufReadPost`/`BufNewFile`) resolve right away, so a function defers nothing there
- **Body-level logic** means requires, computed locals or programmatically built entries in the function body itself (`features/navigation/harpoon/init.lua` loops over pin slots); for a plugin that loads at startup, the function also keeps those requires out of spec-parse time, before plugin rtp paths exist. Callbacks that close over parse-time locals or `Defer` proxies, or `require()` inside their own body, are not body-level logic. Key callbacks take that last form: `keys` resolve at startup, so a utils local shared from the `keys` body would load that module on every startup

### Return Convention

```lua
-- Single spec:
return { 'author/plugin', keys = { ... }, opts = { ... } }

-- List with catppuccin/which-key registration (always in this order):
return { UI.catppuccin(function(...) ... end, 'plugin'), UI.which_key({ ... }), { 'author/plugin', opts = ... } }
```

`UI.catppuccin`'s optional second argument is the lazy.nvim plugin name: the highlight callback then runs when that plugin loads (mechanism in `utils/ui/catppuccin-nvim.lua`) instead of merging into catppuccin's `custom_highlights` at startup. Pass it for plugins loaded by `event`/`ft`/`keys`/`cmd`/`require()`; omit it for `lazy=false` and `BufRead*`-triggered plugins, and when the callback recolors built-in groups used before the plugin loads (nvim-hlslens recolors the search groups). The plugin must have its own `opts` or `config`: the `opts` fragment the helper adds to it would otherwise make lazy.nvim start calling its `setup()`.

### Directory Plugins

Give a plugin the directory form once it has state or more than a few lines of helper logic (wrappers, monkey-patches), keeping its spec file to the lazy.nvim tables and tiny locals such as a desc `PREFIX`: `init.lua` (specs) + `utils.lua` (helpers, keeping any plugin state in a file-local `state` table that only it reads and writes, so specs call its functions) + optional `config/` sub-modules. A helper file serving a single concern is named for it (`chrome/snacks-nvim/zen.lua`, `features/diagnostics/eagle-nvim/pretty-ts-errors.lua`, `features/git/snacks-nvim/lazygit.lua`); `utils.lua` names one plugin's assorted helpers. See `nvim-tree-lua/` (state), `live-preview-nvim/` (wrappers) and `blink-cmp/` (`config/` split); larger plugins split `utils.lua` by concern (`features/search/snacks-nvim/` keeps one module per picker source under `sources/`, `features/formatting/conform-nvim/` the save pipeline under `style-enforcers/`: a runner plus one module per step).

### Split Plugins

A plugin that bundles unrelated features (snacks.nvim) is split into one spec fragment per feature, each filed where a standalone plugin doing that job would live; lazy.nvim merges fragments that share a plugin name. The base fragment sits in the tier that owns loading (`core/snacks-nvim/`) and alone carries `'author/repo'`, `lazy`/`priority`, the opts several features share and features with no domain of their own (the floating terminal).

Every other fragment names the plugin bare (`'snacks.nvim'`) and holds only its feature's `keys`, `opts` (including the module's `styles.<module>` entry) and helpers (`fd snacks-nvim lua` lists every fragment). A new module's config joins the fragment of the domain it serves, picker keymaps included (`<leader>fgb` lives in the git fragment). Helpers stay with the domain that owns them and other domains require them from there (harpoon's picker uses the search fragment's buffers source); `core/snacks-nvim/fullscreen-panels.lua` holds the one helper no single domain owns (the full-screen panels shared by lazygit and the coding agent: their window config and the juggling between them).

- Fragments use plain-table `keys`/`opts`, overriding **Opts and Keys**, and compute anything that needs logic at parse time (`Defer` proxies and locals at the file top, or inline like the keymaps source's `vim.tbl_extend` layout in `features/search/snacks-nvim/init.lua`): lazy.nvim passes a function-valued `keys`/`opts` only the value merged from fragments imported before it, and a non-nil return replaces that value, silently dropping their entries. lazy.nvim concatenates `keys` and deep-merges `opts` in import order (lists inside `opts` are replaced, not merged)
- `init` and `config` resolve to the last fragment that defines them, silently shadowing the rest, so fragments leave both unset. Startup code goes in an extra opts-only fragment whose function `opts` runs it and returns nil, which lazy.nvim resolves right before the plugin's `setup()` (the Lazygit focus tracker, `opts = lazygit.track_last_focus` in `features/git/snacks-nvim/init.lua`)

## Popup Sizing

Size floats through `UI.layout` (`utils/ui/layout.lua`, whose annotations document each helper), never hardcoded dimensions; only cursor-anchored tooltips (e.g. `utils/hl-at-cursor.lua`) size themselves from their content, since `UI.layout` has no cursor-relative placement.

- Snacks picker layouts take `picker_fn`, since their size counts the borders of the windows they draw; windows (`Snacks.win` styles, `nvim_open_win`, nvim-tree) take `popup`/`popup_fn`
- Prefer the function-valued helpers (`popup_fn`, `picker_fn`, the `inline_max_height`/`inline_max_width` caps) wherever the consumer accepts callables, so sizes follow terminal resizes; Snacks accepts them for `width`/`height`/`col`/`row`, not `max_width`/`max_height`

## LSP Setup

Uses native `vim.lsp.enable()` / `vim.lsp.config()` (not `lspconfig[server].setup()`). Each `core/lsp/nvim-lspconfig/lsp/{server}.lua` returns `{ opts = table, setup = function? }`, **not a lazy.nvim spec or a raw `vim.lsp.Config`**: `nvim-lspconfig/utils/server-loader.lua` requires every file only once nvim-lspconfig loads (so computed values are plain file-level locals), then calls `vim.lsp.config(name, opts)` and `setup()` if present. General LSP keymaps live in `nvim-lspconfig/init.lua`, not server files; diagnostics display and the severity jumps live in `config/diagnostics.lua`.

Enable a server in the `servers` list in `nvim-lspconfig/init.lua`; add a `lsp/{server}.lua` only to override nvim-lspconfig's defaults. Servers that drive style-enforcer steps (`eslint`, `oxlint`, `oxfmt`) are also named by server id in their step's `client` field (`features/formatting/conform-nvim/style-enforcers/{eslint,oxlint,oxfmt}.lua`), which limits each step to buffers that server is attached to.

`eslint`, `oxlint` and `oxfmt` are always in `servers` and pick their projects per buffer: `root_dir` looks for each tool's own config, and `workspace_required` keeps them off everywhere else. conform's prettier `condition` asks oxfmt's `root_dir`, so oxfmt projects never run prettier.

`vtsls` and `tsc` are both in `servers`, and `nvim-lspconfig/utils/typescript.lua` activates one per project from its TypeScript: `tsc` for 7+, `vtsls` otherwise. A project that declares 7+ without installing it gets neither, never `vtsls`'s bundled TypeScript.

Server-specific `LspAttach` autocmds use an early-return guard on client name (see `nvim-lspconfig/utils/typescript.lua`).

## Forks

Minimal-diff plugin forks by `hareki` (list them with `rg -o --no-filename "'hareki/[^']+'" lua | sort -u`), plus the parser forks `tree-sitter-glimmer` and `tree-sitter-scss` in the parser table of `core/nvim-treesitter/utils.lua`. The `sync-forks` zsh function rebases all of them except `eagle.nvim` onto upstream, so each fork is upstream's default branch with the fork's own commits on top, no merge commits. A fix every user of the fork should get goes in the fork; config-side wrappers only wire a plugin into this config (a statusline refresh, `UI.layout` sizes).
