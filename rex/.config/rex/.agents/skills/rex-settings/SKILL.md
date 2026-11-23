---
name: rex-settings
description: Rex.app settings and the theme in this Rex config. Use when adding or changing a setting or the theme, including one the user changed in the app.
---

# Settings

1. Read [`docs/conventions/settings.md`](../../../docs/conventions/settings.md).
2. To sync a setting the user changed in the app, find its stored key and value with `defaults read com.superlogical.rex`, then map it to the action and enum value from `rex -C <client label> actions --json`.
3. Leave Apply Settings to the user: the auto-mode classifier refuses a `client.setting.*` call from the shell.

## Check

1. Each new entry names an action that `rex -C <client label> actions --json` lists, with a value from its enum, under the section header the Settings window groups it in.
2. `stylua --check .` and `rex config check` pass.
