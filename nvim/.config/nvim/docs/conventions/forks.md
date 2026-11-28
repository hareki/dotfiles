# Forks

Minimal-diff plugin forks by `hareki` (list them with `rg -o --no-filename "'hareki/[^']+'" lua | sort -u`), plus the parser forks `tree-sitter-glimmer` and `tree-sitter-scss` in the parser table of `core/nvim-treesitter/utils.lua`.

The `sync-forks` zsh function rebases all of them except `eagle.nvim` onto upstream, so each fork is upstream's default branch with the fork's own commits on top, no merge commits.

Keep a fork patch easy to rebase: put the logic in a new file and touch upstream files only with tiny hook lines; leave upstream docs and existing tests alone (new test files are fine) and reuse upstream helpers instead of editing them. After fetching upstream, check with `git merge-tree --write-tree --name-only HEAD FETCH_HEAD`.

A fix every user of the fork should get goes in the fork. Config-side wrappers only wire a plugin into this config (a statusline refresh, `UI.layout` sizes).
