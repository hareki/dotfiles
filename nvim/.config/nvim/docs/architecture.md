# Architecture

How the config boots, where code lives, and which modules other tools reach into. Terms in bold are defined in [GLOSSARY.md](./GLOSSARY.md). The rules for filing and shaping code live in [conventions/](conventions/).

This doc describes shapes and rules, not inventories. Where a list exists, it points to the file that owns it.

## Boot

Boot has two phases. `init.lua` holds the exact sequence and the reason for each step.

1. **Before the first draw**
   - `config.globals` assigns the [globals](#globals) first, so everything after can use them. An invalid `NVIM_INTEGRATION` aborts the boot here.
   - The `config/` modules that no spec owns set options, filetypes and autocmds.
   - `config.lazy` installs lazy.nvim if missing and imports the tiers in order (see [Tiers and domains](#tiers-and-domains)).
   - The few eager specs (`lazy = false`) load.
2. **At `User VeryLazy`**
   - The keymaps get set: Neovim's built-in ones are retitled first, then this config's own.
   - The specs on `event = 'VeryLazy'` load, which is most of them. The rest wait for their own `keys`, `cmd`, `ft` or `event`.

Anything that can wait goes in the second phase. A spec moves to the first only when the first screen needs it.

## Layout

```
lua/
├── config/                  constants and the settings no spec owns
│   ├── globals.lua          assigns the globals
│   └── lazy/                lazy.nvim bootstrap and the tier imports
├── core/                    tier: what everything else stands on
├── chrome/                  tier: what the screen shows
├── features/                tier: what the user does
│   └── {domain}/
│       ├── {plugin}.lua     a spec with no helpers
│       └── {plugin}/        a spec with helpers or state
│           ├── init.lua     the specs
│           └── utils.lua    the helpers and the plugin's state
└── utils/                   shared modules with no spec
```

`core/` and `chrome/` hold specs the same way, without the domain level. [plugin-specs.md](conventions/plugin-specs.md) owns the naming and filing rules.

Outside `lua/`:

- `after/ftplugin/`: buffer options one filetype needs
- `after/queries/`, `indent/`: tree-sitter query and indent overrides
- `tests/`: the test files and their scripts (see [testing.md](./testing.md))
- `assets/`: screenshots for the README and preview fixtures

## Tiers and domains

lazy.nvim imports `core` first, then `chrome`, then each `features` domain. `config/lazy/init.lua` holds the import list.

`core` must stay first because `core/catppuccin-nvim.lua` builds its `opts` in a function that returns a fresh table. A catppuccin **fragment** imported before it would be dropped.

Every tier reads `config/` and `utils/` through the globals. `chrome/lualine-nvim` places a feature's `statusline.lua` without owning it.

## Globals

`config/globals.lua` assigns a few globals so spec files skip the require boilerplate. Each one is a table built from `config/` or `utils/` modules, which you can look up there.

- A global whose modules aren't needed at startup holds a **defer proxy**, which loads the module on first use.
- `config/` modules require each other directly, because the globals don't exist yet while they load.

## Specs and fragments

A plugin's spec usually lives in one file or directory. A few plugins take **fragments** from many files, and lazy.nvim merges them by plugin name in import order.

```
snacks.nvim
├── core/snacks-nvim/                 the base fragment: repo, loading, shared opts
└── {tier or domain}/snacks-nvim      one fragment per feature, filed with its domain
which-key.nvim, catppuccin
└── UI.which_key(), UI.catppuccin()   called from any spec file
```

`fd snacks-nvim lua` lists the snacks fragments. Merging changes how `keys`, `opts`, `init` and `config` behave, and [split-plugins.md](conventions/split-plugins.md) owns those rules.

## Entry points

Tools elsewhere in the dotfiles reach into nvim by module path, in three ways:

- **`--remote-expr`**: a shell script calls a module's function in a running nvim
- **Reading the file**: a tool loads a `config/` module straight off disk
- **The environment**: a tool that opens nvim as its editor sets `NVIM_INTEGRATION`, which boots nvim in **integration** mode. The values it accepts are the hosts in `utils/ui/integration.lua`.

Renaming or moving one of these modules breaks a tool outside nvim. `tests/entry-points.lua` names each one and checks it the way its caller does, so it fails first.

## Cross-cutting pieces

### Style enforcer

`features/formatting/conform-nvim/style-enforcer/` formats, fixes and saves a buffer. Its `init.lua` holds the step list, its order and the time limit.

- Formatting steps run before fixing steps, so the fixes see formatted text.
- A **step** that names an LSP client runs only where that server is attached.
- Each buffer gets one run at a time, and the time limit ends a stuck run.
- A failed format step raises an error notice. A failed fix step raises a warning.

### Popups

`utils/popup.lua` owns floats tied to a **source window**: it hands focus over without firing autocmds, borrows keys in the source window, and closes the float once that window moves on. `tests/popup.lua` is the model test file.

### Full-screen panels

`core/snacks-nvim/fullscreen-panels.lua` manages the **full-screen panels**. It sits in `core` because no single domain owns it.
