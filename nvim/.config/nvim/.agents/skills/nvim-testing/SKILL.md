---
name: nvim-testing
description: Testing this Neovim config in headless nvim with `tests/run.sh`, `tests/probe.sh`, `tests/ab.sh` and the test files under `tests/`. Use when verifying a change, writing or fixing a test, running Lua in a headless nvim, or checking that a refactor changed nothing.
---

# Testing

Each script below gives its usage in its header.

## Pick by question

- **Does it still work?** `tests/run.sh` runs the test files.
- **What does nvim do here?** `tests/probe.sh` runs a one-off Lua payload in nvim booted the way a test file's is.
- **Did the refactor change anything?** `tests/ab.sh` diffs the A/B dump of a revision (default `HEAD`) against the working tree's. Two boots of one config dump identically.

## Writing a test

A test file registers its tests through `tests/lib/helpers.lua` and drives modules through the interface their callers use (`tests/popup.lua` is the model).

## Done

A change is verified when `tests/run.sh` passes, and a refactor when `tests/ab.sh` also shows only the diff rows you can account for.
