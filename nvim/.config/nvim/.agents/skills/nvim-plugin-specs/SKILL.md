---
name: nvim-plugin-specs
description: Plugin specs in this Neovim config, covering where a lazy.nvim spec or native feature (`virtual = true`) is filed, named and shaped, and which spec owns an option, key, autocmd or helper. Use when adding, moving or editing a spec, or registering catppuccin highlights or which-key specs from one.
---

# Plugin specs

1. Read [`docs/conventions/plugin-specs.md`](../../../docs/conventions/plugin-specs.md). When the plugin takes **fragments** from other files (snacks.nvim, which-key.nvim through `UI.which_key`, catppuccin through `UI.catppuccin`), or the spec adds one, read [`docs/conventions/split-plugins.md`](../../../docs/conventions/split-plugins.md) too, before editing: fragments override some of the spec rules.
2. Before finishing, check each spec you touched against every rule in the docs you read.
