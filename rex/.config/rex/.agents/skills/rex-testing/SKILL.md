---
name: rex-testing
description: Checking changes to this Rex config, and testing them live in a throwaway session instead of the user's own. Use when verifying a new or changed binding, action or setting.
---

# Testing

Read [`docs/testing.md`](../../../docs/testing.md). Say in the report which checks stayed untested because their actions are under Untested live.

## Check

Every check under Checks passes, with no warning from `rex keymap --request`, and every live test ran in a probe session that is gone afterwards.
