---
name: zsh-commands
description: The zsh commands this config defines (`build`, `sync-forks`, `tsave`, `trestore`, `yay`, ...), their completions and the aliases. Use when adding or changing a command, a completion or an alias, or when a completion doesn't show up.
---

# zsh commands

## Functions

Each command is an autoloaded function in `.config/zsh/functions/`: one function per file, the filename is the function name, with no `.zsh` extension, since `autoload` names the function after the file. `.zshrc` autoloads the dir by absolute path, so a new file needs no registration.

## Wrapping a command

A wrapper that must reach every launch path (`zsh -c` spawns, nvim's `termopen`, GUI apps) is a shim in `bin/.local/bin/shims/`, since functions and aliases exist only in interactive shells. Follow `bin/.local/bin/shims/mmdc`: `#!/bin/sh`, a comment saying why, `exec <real binary path> "$@"`, tty-only output behind `[ -t 1 ]`, settings through env vars. A shim costs a `/bin/sh` exec (~5ms), so a slow PATH lookup is better fixed at the install location.

## Completions

Every custom completion goes in `.config/zsh/compdefs/`, one file per command named `_<command>` (e.g. `_build`, `_tv`) whose first line is `#compdef <command>`. This covers the functions above and external commands alike. The file body _is_ the completion function, so it needs no wrapper and no trailing `compdef` call. The directory is on `fpath`, so compinit registers the tag and autoloads the body on first use. A command family may share one file, and a vendor script meant for `.zshrc` gets a compdef that sources it on first use (both: `_gcloud`).

### Stale completion dump

`$ZSH_COMPDUMP` caches only the `command => function` mapping, and `completion.zsh` rebuilds it when an `fpath` dir's mtime passes it. So:

- Picked up on the next shell, no action needed: editing a compdef's body (bodies are autoloaded from `fpath` at completion time, never cached), and adding, deleting or renaming a compdef, here or in a third-party `fpath` dir.
- Goes **stale**, since the dir's mtime doesn't change: rewriting a `#compdef` line in place without creating or renaming a file in the dir (an editor's temp file or atomic save does bump it).
- Fix: `rm $ZSH_COMPDUMP`, then start a new shell.

## Aliases

Aliases go in `.config/zsh/aliases.zsh`. Commands run through `$SHELL -c` (television's cables) spell out their flags, since only `.zshenv` reaches those shells and it stays free of aliases.

## Check

1. Run the command's test file when it has one (`tests/run.zsh <command>`, the `zsh-testing` skill). A command that pushes, quits or updates (`sync-forks`, `tsave`, `yay`) is tested only there.
2. For a new or renamed compdef, drive a TAB through the scratch-boot probe in the `zsh-testing` skill's [completions.md](../zsh-testing/completions.md).
