---
name: nvim-testing
description: Testing this Neovim config in headless nvim with `tests/run.sh`, `tests/probe.sh`, `tests/ab.sh` and the test files under `tests/`. Use when verifying a change, writing or fixing a test, running Lua in a headless nvim, or checking that a refactor changed nothing.
---

# Testing

Every headless boot goes through one of three scripts. Each script's header gives its usage, and `tests/lib/env.sh` the boot rules they apply.

## Pick by question

- **Does it still work?** `tests/run.sh [words]` runs the test files in `tests/` (all, or those whose name contains a word), each in its own headless nvim booted on the working tree with `VeryLazy` fired, all side by side.
- **What does nvim do here?** `tests/probe.sh <payload.lua>` boots the working tree the way a test file's nvim boots and runs a one-off Lua payload in it; the payload prints with `io.stdout:write`, registers tests, or both.
- **Did the refactor change anything?** `tests/ab.sh [rev]` boots `rev` (default `HEAD`) and the working tree with every plugin loaded and diffs what each config defines: maps (global and per filetype), highlights, autocmds, commands, options, plugin specs and resolved opts, LSP configs, which-key specs and icons, and the modules on the startup path. Two boots of one config dump identically, so every diff row is a change to account for.

## Writing a test

- A test file registers its tests through `tests/lib/helpers.lua` and drives modules through the interface their callers use (`tests/popup.lua` is the model).
- What a test acquires through the helpers (`t.spy`, `t.set`, `t.buffer`, `t.file`, `t.tab`, `t.float`, a picker) is undone when it ends, pass or fail; `t.cleanup(fn)` covers what they cannot undo (a module's own state, a window, an augroup).
- `tests/entry-points.lua` checks every call that outside callers send to an entry point; a new entry point or caller gets its check there.

## Done

A change is verified when `tests/run.sh` passes, and a refactor when `tests/ab.sh` also shows only the diff rows you can account for.
