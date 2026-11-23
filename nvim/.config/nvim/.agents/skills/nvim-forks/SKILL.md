---
name: nvim-forks
description: Plugin forks this Neovim config runs, the `hareki/*` plugins and the tree-sitter parser forks. Use when a fix belongs in a plugin's own code, or when changing, syncing or adding a fork.
---

# Forks

Read [`docs/conventions/forks.md`](../../../docs/conventions/forks.md) before the change.

When a change adds or removes a `hareki/*` plugin fork, update the README in the same commit:

- The plugin fork count on the Features list (`🍴 N plugin forks`). Recount with `rg -o --no-filename "'hareki/[^']+'" lua | sort -u | wc -l`, which leaves out the parser forks.
- The `([fork](https://github.com/hareki/...))` link after the plugin's entry under Plugins.
