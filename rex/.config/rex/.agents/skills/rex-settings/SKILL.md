---
name: rex-settings
description: The Rex.app settings record (`config/settings.lua`), Apply Settings and the imported theme. Use when adding or changing a setting, syncing one the user changed in the Settings window, or changing the theme.
---

# Settings

1. Read [`docs/conventions/settings.md`](../../../docs/conventions/settings.md).
2. To sync a setting the user changed in the app, find its stored key and value with `defaults read com.superlogical.rex`, then map it to the action and enum value from `rex -C <client label> actions --json`.
3. Leave Apply Settings to the user: the auto-mode classifier refuses a `client.setting.*` call from the shell.

## Check

1. Each new entry names an action that `rex -C <client label> actions --json` lists, with a value from its enum, under the section header the Settings window groups it in.
2. `stylua --check .` and `rex config check` pass.
