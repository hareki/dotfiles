---
name: rex-testing
description: Testing this Rex config with `rex config check`, `rex keymap`, `rex do` and probe sessions. Use when verifying a change, running a custom action before a reload, or reading the bytes a key sends.
---

# Testing

Read [`docs/testing.md`](../../../docs/testing.md). Say in the report which checks stayed untested because their actions are under Untested live.

## Check

Every check under Checks passes, with no warning from `rex keymap --request`, and every live test ran in a probe session that is gone afterwards.
