# Keymaps

How a keymap is defined and where it goes, how its `desc` is titled, and how which-key groups and icons are registered.

## Defining a keymap

- A keymap sits in the `keys` of the spec that owns it ([Ownership](plugin-specs.md#ownership)), or in `config/keymaps.lua` when no single spec owns it.
- A key that runs an Ex command takes a `<cmd>...<cr>` string, not a function calling `vim.cmd`, unless it needs runtime values or several statements.
- A useful keymap a plugin creates on its own is reclaimed rather than deleted: set the plugin's option for that map to `false`, then re-declare the same lhs in the spec's `keys`, calling the plugin's public function, with a title-case `desc` (debugprint's `[g`/`]g`/`[G`/`]G` in `features/diagnostics/debugprint-nvim.lua`). The config turns plugin maps off to control their load timing, descs and which-key grouping, so deleting a useful one loses the key.

## Picker keymaps

A plugin's picker keymap goes under `<leader>f` (Find), even when its plugin has a which-key group of its own: harpoon (`<leader>H`) => `<leader>fp`, debugprint (`<leader>?`) => `<leader>f?`, live-preview (`<leader>p`) => `<leader>fP`.

Before binding one, list the free `<leader>f` letters, and mirror the plugin's group key when it is free; otherwise take an uppercase or mnemonic letter, the way `fh`/`fH` split highlights and help. Keep the words the plugin's which-key icon rule matches in the `desc` ("Live Preview: Find File" for the `live preview` pattern), so its icon follows the key into the Find menu.

## Titles

Every keymap gets a `desc` in **CMOS 18 title case** (rule 8.160): capitalize the first, last and all major words, and lowercase only:

- articles: a, an, the
- coordinating conjunctions: and, but, or, nor, for
- `to` and `as`
- prepositions of **four or fewer letters**: in, of, on, at, by, with, from, into, over

So it is "Go to Definition". Prepositions of **five or more letters are capitalized** (Under, After, Before, Above, Below, Between, Within, Through, Without, About, Until, During), as in "Toggle Fold Under Cursor".

## which-key

which-key groups, icon rules and triggers are registered from the owning spec file with `UI.which_key({ specs?, rules?, triggers? })`. An icon rule's color is a Catppuccin palette key ([Icons and colors](ui.md#icons-and-colors)): `chrome/which-key-nvim/icon-rules.lua` raises on any other name, which-key's own `cyan`, `purple` and `orange` included.
