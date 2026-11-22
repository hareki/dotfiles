---
name: nvim-testing
description: Testing this Neovim config in headless nvim with `tests/run.sh`, `tests/probe.sh`, `tests/ab.sh` and the test files under `tests/`. Use when verifying a change, writing or fixing a test, running Lua in a headless nvim, or checking that a refactor changed nothing.
---

# Testing

1. Read [`docs/testing.md`](../../../docs/testing.md), then the header of each script you run.
2. A change is verified when `tests/run.sh` passes, and a refactor when `tests/ab.sh` also shows only the diff rows you can account for.
