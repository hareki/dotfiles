# Commands

How the commands this config defines (`build`, `sync-forks`, `tsave`, `trestore`, `yay`, ...) are written, wrapped and completed, and how aliases reach the shells that run them.

## Functions

Each command is a function in `.config/zsh/functions/`, in a file named after it with no extension. `.zshrc` autoloads every file there, so a new one needs no registration.

## Wrapping a command

A wrapper that must reach every launch path (`zsh -c` spawns, nvim's `termopen`, GUI apps) is a shim in `bin/.local/bin/shims/`, since functions and aliases exist only in interactive shells. Follow the shims there: `#!/bin/sh`, a comment saying why, then an `exec` of the real binary's path with `"$@"`. A shim costs a `/bin/sh` exec (~5ms), so a slow PATH lookup is better fixed at the install location.

## Completions

Every custom completion goes in `.config/zsh/compdefs/`, one file per command named `_<command>` (e.g. `_build`, `_tv`) whose first line is `#compdef <command>`. This covers the functions above and external commands alike. The file body _is_ the completion function: no wrapper and no trailing `compdef` call, since compinit registers the tag from `fpath`. A command family may share one file, and a vendor script meant for `.zshrc` gets a compdef that sources it on first use (both: `_gcloud`).

### Stale completion dump

`$ZSH_COMPDUMP` caches only the `command => function` mapping, and `completion.zsh` rebuilds it when an `fpath` dir's mtime passes it. So:

- Picked up on the next shell, no action needed: editing a compdef's body (bodies are autoloaded from `fpath` at completion time, never cached), and adding, deleting or renaming a compdef, here or in a third-party `fpath` dir.
- Goes **stale**, since the dir's mtime doesn't change: rewriting a `#compdef` line in place without creating or renaming a file in the dir (an editor's temp file or atomic save does bump it).
- Fix: `rm $ZSH_COMPDUMP`, then start a new shell.

## Aliases

Commands run through `$SHELL -c` (television's cables) spell out an alias's flags, since only `.zshenv` reaches those shells and it stays free of aliases.
