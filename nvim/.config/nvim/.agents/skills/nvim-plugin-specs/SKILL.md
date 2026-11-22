---
name: nvim-plugin-specs
description: Plugin specs in this Neovim config, covering where a lazy.nvim spec or native feature (`virtual = true`) is filed, named and shaped, and which spec owns an option, key, autocmd or helper. Use when adding, moving or editing a spec, or registering catppuccin highlights or which-key specs from one.
---

# Plugin specs

Every plugin, and every native feature, is a lazy.nvim **spec** filed by tier and domain (`GLOSSARY.md` defines the terms). Before finishing, check each spec you touched against every rule below.

When the plugin is snacks.nvim, or a spec adds a `'snacks.nvim'` **fragment**, read [`split-plugins.md`](split-plugins.md) first: fragments override some of these rules.

## Filing

- Tiers under `lua/`: `core/` holds what everything else stands on (theme, icons, snacks, sessions, treesitter, the LSP setup in `core/lsp/`), `chrome/` what the screen shows, `features/{domain}/` what the user does.
- `config/lazy/init.lua` imports `core` (**must stay first**), `core.lsp`, `chrome`, then each `features.{domain}`. lazy.nvim's `import` loads only direct `*.lua` files and `*/init.lua` modules, so `core/lsp/` and every new domain dir need their own entry.
- Name a plugin's spec file or dir after its GitHub repo name (the part after `/`), with **every `.` replaced by `-`**: `noice.nvim` => `noice-nvim.lua`, `snacks.nvim` => `snacks-nvim/`, `mini.ai` => `mini-ai/`, `nvim-colorizer.lua` => `nvim-colorizer-lua.lua`. When the repo name alone is meaninglessly generic, prefix the author (`catppuccin/nvim` => `catppuccin-nvim.lua`), never the bare module name: LuaLS resolves `require('catppuccin')` by basename, so a `catppuccin.lua` anywhere under `lua/` shadows the plugin and every `.setup` on it reports `undefined-field`.
- A spec file holds the lazy.nvim tables and tiny locals such as a desc `PREFIX`. Once a plugin has state or more than a few lines of helper logic (wrappers, monkey-patches), it takes the directory form: `init.lua` (specs) + `utils.lua` (helpers, keeping any plugin state in a file-local `state` table that only it reads and writes, so specs call its functions) + optional `config/` sub-modules. Models: `nvim-tree-lua/` (state), `live-preview-nvim/` (wrappers), `blink-cmp/` (`config/` split).
- A helper file serving a single concern is named for it (`chrome/snacks-nvim/zen.lua`, `features/git/snacks-nvim/lazygit.lua`); `utils.lua` names one plugin's assorted helpers. Larger plugins split `utils.lua` by concern (`features/search/snacks-nvim/` keeps one module per picker source under `sources/`, `features/formatting/conform-nvim/` the style enforcer under `style-enforcer/`: its run plus one module per step).
- The statusline piece a feature shows is its `statusline.lua` (`features/navigation/harpoon/statusline.lua`: `get`, plus `cond`, `icon` and `color` as needed), which `chrome/lualine-nvim/init.lua` only places; `chrome/lualine-nvim/components/` keeps the pieces no feature owns.

## Ownership

An option, autocmd, command or key that exists for one plugin or native feature sits in that spec: options in `init` (they apply before the first draw), keys in `keys`, commands in `cmd`, autocmds in `config`. `config/options.lua`, `config/autocmds.lua` and `config/keymaps.lua` keep only what no single spec owns.

A buffer option one filetype needs is an `after/ftplugin/<filetype>.lua` (`ghostty.lua`, `man.lua`). It reads no globals and requires no config module, since lazygit's diff renderer runs `nvim --clean` with `after/` on its runtimepath.

## Native features

A feature built on Neovim alone, with no plugin behind it, is a spec as well: `virtual = true` right after its name, which stands in for `'author/repo'` (`{ 'hl-at-cursor', virtual = true, cmd = 'HlAtCursor', keys = { ... } }`). lazy.nvim installs nothing for it and adds nothing to the runtimepath, while `init`, `cmd`, `event`, `keys` and `config` work as they do for a plugin. File and name it like a plugin (`features/diagnostics/hl-at-cursor/` with `init.lua` + `utils.lua`), so deleting that file or directory removes the feature.

## Loading

Specs are lazy by default (`defaults.lazy = true`) and load on `event` (mostly `VeryLazy`), `ft`, `keys` or `cmd`, on first `require()`, or as a dependency. Only catppuccin, snacks.nvim, auto-session (`priority = Conf.priority.CORE`) and noice.nvim are eager (`lazy = false`); `priority` only puts the first three ahead of noice, so lazy specs leave it unset.

## Key order

`'author/repo'` => `enabled`/`cond`/`name`/`branch`/`version`/`build`/`main` => `lazy`/`priority` => `cmd`/`event`/`ft` => `dependencies` => `init` => `keys` => `opts`/`opts_extend` => `config`

## Opts and keys

Make `opts` or `keys` a function (`opts = function() return { ... } end`) exactly when the function buys deferral or body-level logic; otherwise it stays a plain table, including an empty `opts = {}`:

- **Deferral** comes only to a lazy-loaded plugin's `opts`: lazy.nvim parses every spec file at startup to learn load triggers, and the function builds the table only when the plugin loads. `keys` and the `opts` of plugins that load at startup anyway (`lazy = false`, or unfiltered buffer/window events such as `BufReadPost`/`BufNewFile`) resolve right away, so a function defers nothing there
- **Body-level logic** means requires, computed locals or programmatically built entries in the function body itself (`features/navigation/harpoon/init.lua` loops over pin slots); for a plugin that loads at startup, the function also keeps those requires out of spec-parse time, before plugin rtp paths exist. Callbacks that close over parse-time locals or `Defer` proxies, or `require()` inside their own body, are not body-level logic. Key callbacks take that last form: `keys` resolve at startup, so a utils local shared from the `keys` body would load that module on every startup

## Return convention

```lua
-- Single spec:
return { 'author/plugin', keys = { ... }, opts = { ... } }

-- List with catppuccin/which-key registration (always in this order):
return { UI.catppuccin(function(...) ... end, 'plugin'), UI.which_key({ ... }), { 'author/plugin', opts = ... } }
```

`UI.catppuccin.integration('name')` goes ahead of both: it turns on catppuccin's own support for the plugin (a key of its `integrations` table) from the plugin's spec file, since `auto_integrations` is off.

`UI.catppuccin`'s optional second argument is the lazy.nvim plugin name: the highlight callback then runs when that plugin loads (mechanism in `utils/ui/catppuccin-nvim.lua`) instead of merging into catppuccin's `custom_highlights` at startup. Pass it for plugins loaded by `event`/`ft`/`keys`/`cmd`/`require()`; omit it for `lazy=false` and `BufRead*`-triggered plugins, and when the callback recolors built-in groups used before the plugin loads (nvim-hlslens recolors the search groups). The plugin must have its own `opts` or `config`: the `opts` fragment the helper adds to it would otherwise make lazy.nvim start calling its `setup()`.
