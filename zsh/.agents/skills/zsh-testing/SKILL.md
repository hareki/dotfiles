---
name: zsh-testing
description: Testing the zsh package with `tests/run.zsh`, `tests/ab.zsh` and the test files under `tests/`. Use when verifying a change, writing or fixing a test, or booting a scratch shell of the config.
---

# zsh testing

Every harness here builds on `tests/lib/`. Each file in it, and each test file, opens with a header that says what it covers and how, so read the header before running or extending one.

## Pick the run

- **A config change** (`.zshenv`, `.zshrc`, `.zplugins`, a module): `tests/ab.zsh [rev]`, against `HEAD` by default. Two boots of one tree dump identically, so every diff row is a change to account for, a module moved in the `.zshrc` loop included. `ZT_AB_KEEP=<dir>` keeps both dumps.
- **An override, or after `yay`**: `tests/run.zsh overrides`.
- **A command**: `tests/run.zsh <words>` runs the test files whose name contains a word. Some files cover code outside this package:
  - `snapshots`: `tsave`, `trestore` and the tmux package's `scripts/resurrect-snapshots.zsh` and `claude-panes.zsh`.
  - `tsave`: also the nvim config's `core/auto-session/tsave.lua`.
  - `ctb`: also Claude Code's Stop hook and status line (`claude-code/.claude`).
  - `done-gate`: `claude-code/.claude/hooks/done-gate.sh` and the two hooks that start with it.
- **A completion**: a TAB in a scratch boot, through [completions.md](completions.md).
- **A comment-only change**: prove it with [comment-only.md](comment-only.md), which compares zsh's own parse of the old and new file.
- **Before a commit**: `tests/run.zsh` with no words runs every file side by side (~13s).

## Write a test

A test file drives a command through its own interface, with stand-ins for what it reaches, and asserts through `tests/lib/helpers.zsh`, which also sets an interactive shell's options for it. It ends on `t_done`.

- **Booting the config**: `zt_home` and `zt_boot` in `tests/lib/env.zsh`. A test's own questions for a booted shell go in a file `ZT_PROBE` names.
- **Driving git**: `zt_repos` in `tests/lib/repos.zsh` first, which proves git reaches no remote but a local file before the test builds on it.
- **Claude Code in a pane**: the stand-in in `tests/lib/claude.zsh`.

## Check

Every test file the change touches, or that covers a touched file, passes, and `tests/ab.zsh` shows only the diff rows the change explains.
