# Copilot Instructions for Neovim Config

## Architecture

**lazy.nvim** config organized into 3 plugin directories under `lua/plugins/`:

| Directory            | Purpose                                                          | Examples                                                                          |
| -------------------- | ---------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| `core/`              | Bedrock + infrastructure — theme, icons, snacks, treesitter, LSP | catppuccin, mini-icons, snacks/, nvim-treesitter, noice, lsp/                     |
| `features/{domain}/` | Domain features (8 sub-groups)                                   | navigation/, completion/, git/, editing/, search/, diagnostics/, formatting/, ai/ |
| `chrome/`            | Visual-only — statusline, decorations, which-key                 | lualine/, dropbar/, nvim-ufo/, reticle/, hlchunk, which-key/                      |

Cross-cutting concerns live in `lua/services/` (statusline, cursorline, keymap_registry) to avoid cross-tier coupling.

**Boot order** (`init.lua`): `vim.loader.enable` → globals → options → autocmds → usercmds → keymaps → lazy

### Globals (`lua/config/globals.lua`)

Six globals available everywhere — `Notifier` is lazy-loaded, `Snacks` is set by snacks.nvim:

| Global       | Source                            | Usage                                                             |
| ------------ | --------------------------------- | ----------------------------------------------------------------- |
| `Defer`      | `utils.lazy-require`              | `Defer.on_index()`, `Defer.on_exported_call()`                    |
| `Notifier`   | Lazy proxy → `utils.notifier`     | `Notifier.info('msg')`, `Notifier.warn('msg', { title = 'T' })`   |
| `Catppuccin` | `utils.ui.catppuccin`             | Highlight registration in plugin specs                            |
| `Icons`      | `config.icons`                    | All icons — never hardcode icon strings                           |
| `Priority`   | `config.priority`                 | `CORE = 1000`, `CHROME = 900`                                     |
| `Snacks`     | Set by snacks.nvim (`lazy=false`) | `Snacks.picker.*`, `Snacks.terminal.*`, `Snacks.bufdelete()` etc. |

### Key Modules

- `config/size.lua` — popup presets (`sm`/`md`/`lg`/`vertical_lg`/`full`), `side_preview`, `side_panel`, `inline_popup`
- `config/palette_ext.lua` — extended colors (`blue0-2`, `green0-1`, `surface15`) beyond standard catppuccin
- `config/picker.lua` — shared picker UI constants (`prompt_prefix`, `preview_title`, `telescope_preview_title`)
- `services/` — decoupled cross-cutting: `statusline` (have_status_line, refresh), `cursorline` (set_cursorline), `keymap_registry` (desc_overrides)
- `utils/ui.lua` — `popup_config(size, with_border)`, `catppuccin(fn)`, `get_palette()`, `highlight()`, `blend_hex()`
- `utils/common.lua` — `noautocmd(fn)`, `focus_win(win)`, `is_float_win()`, `list_extend(...)`
- `utils/notifier.lua` — rich notifications; accepts strings or `{text, highlight}` tuples

## Plugin Patterns

**Return convention** — single spec (majority) or list of specs (when Catppuccin highlights needed):

```lua
return { 'author/plugin', keys = { ... }, opts = { ... } }                          -- single
return { Catppuccin(function(p, sp, ext) ... end), { 'author/plugin', opts = ... } } -- list
```

**Directory plugins** — for state or large configs: `init.lua` (specs) + `utils.lua` (`M.state = {}`) + optional `config/` sub-modules. See `nvim-tree/`, `blink-cmp/`.

**Catppuccin highlights** — `Catppuccin(fn)` callback receives 3 args: `palette` (mocha), `sub_palette` (latte), `extension` (palette*ext). Underscore unused: `Catppuccin(function(palette, *, extension) ... end)`.

**Popup sizing** — use `popup_config(size, with_border)`, never hardcode. **Gotcha**: Telescope needs `with_border=true`; Snacks/nvim-tree need `false`.

## Conventions

### Plugin Spec Key Order

`'author/repo'` → `enabled`/`cond`/`name`/`branch`/`version`/`build`/`main` → `lazy`/`priority` → `cmd`/`event`/`ft` → `dependencies` → `keys` → `init` → `opts`/`opts_extend` → `config`

### Keymaps

- `desc` in CMOS 18 title case: "Find Files", "Go to Definition"
- `<A-key>` for Alt bindings; `<leader>` for command groups

### LspAttach Guard Pattern

Server-specific autocmds early-return on client name mismatch:

```lua
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('vtsls_lsp_attach', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not (client and client.name == 'vtsls') then return end
  end,
})
```

### Code Style

- stylua: 100-char lines, 2-space indent
- LuaLS `---@class`/`---@param`/`---@return`/`---@alias` annotations for public APIs
- Assign `require()` to a local before use — never chain `require('x.y').method()`
- Use `vim.cmd` structured API — never `<CMD>...<CR>` in keymaps

## LSP Setup

Uses Neovim 0.11+ `vim.lsp.enable()` (not `lspconfig[server].setup()`). Per-server configs in `plugins/core/lsp/nvim-lspconfig/lsp/{server}.lua` — **these are NOT lazy.nvim specs**, they return `{ opts, setup }`:

```lua
return {
  opts = { ... },            -- passed to vim.lsp.config(name, opts)
  setup = function() ... end -- optional: LspAttach autocmds, user commands
}
```

~13 servers enabled; 7 have config files (eslint, jsonls, lua_ls, tailwindcss, typos_lsp, vtsls, yamlls); the rest use defaults. General LSP keymaps live in `nvim-lspconfig/init.lua`, not server files. Mason in `plugins/core/lsp/mason.nvim.lua`.

## Formatting & Linting

Async pipeline in `utils/formatters/async_style_enforcer.lua`: `M.run()` formats + lints one buffer (buffer lock → conform → registered linters → save → release). `M.run_all()` dispatches to all modified buffers in parallel.

Linter registration (`utils/linters/init.lua`): `M.register(name, filetypes, runner)`. ESLint registers during LspAttach using fix-all code action (not CLI).

## Snacks Picker

Custom pickers in `plugins/core/snacks/pickers/` export `M.show(user_opts)`. Supporting utils in `snacks/utils/`: formatters, transformers, sorters, cache, state. `picker_query_persister.lua` persists search queries across invocations.

## Plugin Import Order

In `config/lazy/init.lua` — `plugins.core` **must be first** (catppuccin has `priority = CORE`):

```lua
spec = {
  { import = 'plugins.core' },     { import = 'plugins.core.lsp' },
  { import = 'plugins.chrome' },   -- chrome before features
  { import = 'plugins.features.navigation' },  { import = 'plugins.features.completion' },
  { import = 'plugins.features.git' },         { import = 'plugins.features.editing' },
  { import = 'plugins.features.search' },      { import = 'plugins.features.diagnostics' },
  { import = 'plugins.features.formatting' },  { import = 'plugins.features.ai' },
}
```

All lazy by default. Use `event = 'VeryLazy'` or keymap triggers. **Gotcha**: nvim-lspconfig uses `VeryLazy` instead of `LazyFile` to avoid directory file-type detection issues.

## Forks (author = `hareki`)

15+ minimal-diff forks; **Tab** = toggle focus (list↔preview, float↔main); **`<C-t>`** = toggle side-panel mode. Updated via [wei/pull](https://github.com/wei/pull); features toggleable.
