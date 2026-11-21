---
name: zsh-commands
description: The zsh commands this config defines (`build`, `sync-forks`, `ctb`, `yay`, ...), their completions and the aliases. Use when adding or changing a command, a completion or an alias, or when a completion doesn't show up.
---

# zsh commands

Read [`docs/conventions/commands.md`](../../../docs/conventions/commands.md) before the change.

## Check

1. Run every test file that covers the command, which the `zsh-testing` skill shows how to find.
2. For a new or renamed compdef, drive a TAB through the scratch-boot probe in the `zsh-testing` skill's [completions.md](../zsh-testing/completions.md).
