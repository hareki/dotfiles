---
name: rex-testing
description: Testing this Rex config with `rex config check`, `rex keymap`, `rex do` and probe sessions. Use when verifying a change, running a custom action before a reload, or reading the bytes a key sends.
---

# Testing

Read [`docs/testing.md`](../../../docs/testing.md).

- Create a probe session for every live test, and `rex kill` it when done.
- Leave `client.tab.close`, `client.close` and `client.setting.*` unrun: they reach the user's app, and the auto-mode classifier refuses `client.setting.*` probes. Say in the report which checks stayed untested for that reason.

## Check

`stylua --check .`, `rex config check` and `rex keymap` pass, and every live test ran in a probe session that is gone afterwards.
