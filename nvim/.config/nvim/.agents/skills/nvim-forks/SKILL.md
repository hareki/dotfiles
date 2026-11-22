---
name: nvim-forks
description: Plugin forks this Neovim config runs, the `hareki/*` plugins and the tree-sitter parser forks. Use when a fix belongs in a plugin's own code, or when changing, syncing or adding a fork.
---

# Forks

Minimal-diff plugin forks by `hareki` (list them with `rg -o --no-filename "'hareki/[^']+'" lua | sort -u`), plus the parser forks `tree-sitter-glimmer` and `tree-sitter-scss` in the parser table of `core/nvim-treesitter/utils.lua`.

The `sync-forks` zsh function rebases all of them except `eagle.nvim` onto upstream, so each fork is upstream's default branch with the fork's own commits on top, no merge commits.

A fix every user of the fork should get goes in the fork. Config-side wrappers only wire a plugin into this config (a statusline refresh, `UI.layout` sizes).
