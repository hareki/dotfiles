# AGENTS.md

## Overview

A zsh config for macOS, with Homebrew at `/opt/homebrew/`. `sync-dots zsh` deploys it to `$HOME` with GNU stow, minus what `.stow-local-ignore` lists: the package metadata at the root (these docs, `assets`, `tests`) and the skills' dirs, whose names `~/.agents` and `~/.claude` already belong to other packages. [GLOSSARY.md](./GLOSSARY.md) defines the terms the docs, the code and the tests use; [README.md](./README.md) maps the files.

The rules for one kind of change (startup and where a setting goes, commands and completions, testing) are project skills in `.agents/skills/`, which `.claude/skills` links to; edit them there.

## Tests

Test through `tests/run.zsh` and `tests/ab.zsh`, whose scratch shells follow the rules in `tests/lib/env.zsh`, each of which cost a real incident: dummy API keys, `env -i` for every boot, a scratch HOME and TMPDIR. Never xtrace a boot (an xtrace of `.zshenv` once printed both real keys into a transcript) and never dump the environment (`ps -E`).

Never run `sync-forks`, `tsave` or `yay` for real to test them: they force-push every fork, quit every nvim and Claude Code session, and update every package manager. Their test files run them against stand-ins.
