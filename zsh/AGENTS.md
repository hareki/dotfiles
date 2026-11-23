# AGENTS.md

## Overview

A zsh config for macOS, with Homebrew at `/opt/homebrew/`. `sync-dots zsh` deploys it to `$HOME` with GNU stow, minus what `.stow-local-ignore` lists. [docs/GLOSSARY.md](./docs/GLOSSARY.md) defines the terms the docs, the code and the tests use; [README.md](./README.md) maps the files.

The rules for one kind of change live in `docs/`, one file per topic, written for people and agents alike: conventions in `docs/conventions/`, the overrides' reasons and the testing guide beside them. A project skill in `.agents/skills/` (`.claude/skills` links there) points the agent at its doc and holds only the agent's own steps and checks, so a new convention goes in a doc.

## Tests

Test through `tests/run.zsh` and `tests/ab.zsh`, whose scratch shells follow the rules in `tests/lib/env.zsh`, each of which cost a real incident: dummy API keys, `env -i` for every boot, a scratch HOME and TMPDIR. Never xtrace a boot (an xtrace of `.zshenv` once printed both real keys into a transcript) and never dump the environment (`ps -E`).

Never run `sync-forks`, `tsave` or `yay` for real to test them: they force-push every fork, quit every nvim and Claude Code session and the tmux server, and update every package manager. `tests/sync-forks.zsh` and `tests/tsave.zsh` run the first two against stand-ins; `yay` has no test.
