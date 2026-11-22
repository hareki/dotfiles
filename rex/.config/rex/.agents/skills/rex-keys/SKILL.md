---
name: rex-keys
description: Key bindings in this Rex config, covering where a binding goes, the cmd => alt scheme, raw bytes through `send_text`, the app's shadowed default shortcuts and pane navigation. Use when adding or changing a binding, or the key one sends to the program in a pane.
---

# Keys

1. Read [`docs/conventions/keys.md`](../../../docs/conventions/keys.md).
2. Before binding a cmd key, read the shortcuts on `/rex/docs/reference/mac-actions` through the `superlogical` MCP server's `read_doc`, and name in your report any default the binding shadows.

## Check

1. Every key a binding sends carries its program comment, and the program it names listens for that exact key in its own file (Files outside this config).
2. `rex keymap` lists the binding, and for a sent key, a `/bin/cat -v` probe pane shows the bytes the program expects (the `rex-testing` skill).
