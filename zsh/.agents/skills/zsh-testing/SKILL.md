---
name: zsh-testing
description: Testing the zsh package with `tests/run.zsh`, `tests/ab.zsh` and the test files under `tests/`. Use when verifying a change, writing or fixing a test, or booting a scratch shell of the config.
---

# zsh testing

1. Read [`docs/testing.md`](../../../docs/testing.md), then the header of every harness and test file before running or extending it.
2. Two runs have a recipe of their own here:
   - **A completion**: drive the TAB in a scratch boot through [completions.md](completions.md).
   - **A comment-only change**: prove it with [comment-only.md](comment-only.md), which compares zsh's own parse of the old and new file.

## Check

Every test file the change touches, or that covers a touched file, passes, and `tests/ab.zsh` shows only the diff rows the change explains.
