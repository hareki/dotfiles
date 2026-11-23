# Split plugins

A plugin that bundles unrelated features (snacks.nvim) is split into one spec **fragment** per feature, each filed where a standalone plugin doing that job would live; lazy.nvim merges fragments that share a plugin name. Every fragment reuses the plugin's file name in its tier or domain dir (`core/snacks-nvim/`, `features/editing/snacks-nvim.lua`); `fd snacks-nvim lua` lists them.

The base fragment sits in the tier that owns loading (`core/snacks-nvim/`) and alone carries `'author/repo'`, `lazy`/`priority`, the opts several features share and features with no domain of their own (the floating terminal).

Every other fragment names the plugin bare (`'snacks.nvim'`) and holds only its feature's `keys`, `opts` (including the module's `styles.<module>` entry) and helpers.

- A plugin with a spec of its own that plugs one piece into a snacks module adds it from that spec file, as a `'snacks.nvim'` opts fragment beside its own spec (trouble.nvim's picker action and its `<C-t>` keys; `rg "'snacks.nvim'" lua` lists these too).
- A new module's config joins the fragment of the domain it serves, picker keymaps included (`<leader>fgb` lives in the git fragment).
- Helpers stay with the domain that owns them, and other domains require them from there (harpoon's picker uses the search fragment's buffers source). `core/snacks-nvim/terminals.lua` holds the one helper no single domain owns, the Snacks terminals (the floating terminal and the full-screen panels).

## Where fragments differ from single specs

These rules hold for every plugin that takes fragments from other files, not only snacks.nvim: each `UI.which_key` adds a which-key.nvim fragment, each `UI.catppuccin` a catppuccin one. The `core/` which-key fragments (auto-session, nvim-lspconfig) merge before `chrome/which-key-nvim/init.lua`, so its `opts` stays a plain table. `core/catppuccin-nvim.lua`'s function `opts` returns a fresh table, which drops nothing only because no catppuccin fragment is imported before it: the reason `core` must stay first.

- Fragments use plain-table `keys`/`opts`, overriding [Opts and keys](plugin-specs.md#opts-and-keys), and compute anything that needs logic at parse time (`Defer` proxies and locals at the file top, or inline like the zen style's `vim.tbl_extend` in `chrome/snacks-nvim/init.lua`): lazy.nvim passes a function-valued `keys`/`opts` only the value merged from fragments imported before it, and a non-nil return replaces that value, silently dropping their entries. lazy.nvim concatenates `keys` and deep-merges `opts` in import order (lists inside `opts` are replaced unless the spec's `opts_extend` names them)
- `init` and `config` resolve to the last fragment that defines them, silently shadowing the rest, so fragments leave both unset. Startup code goes in an extra opts-only fragment whose function `opts` runs it and returns nil, which lazy.nvim resolves right before the plugin's `setup()` (the Lazygit focus tracker, `opts = lazygit.track_last_focus` in `features/git/snacks-nvim/init.lua`)
