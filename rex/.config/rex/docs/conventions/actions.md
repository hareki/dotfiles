# Actions

How a custom action is filed, named and titled, and which calls it builds on.

## Files

- `init.lua` only requires modules: `config.keymaps`, then one line per feature
- `features/<name>.lua` holds one feature: a custom action (`rex.action`) with the keys that run it, the keys sent to the program in the pane (`program-keys.lua`, [Where a binding goes](keys.md#where-a-binding-goes)), or a resume rule (`nvim-resume.lua`); deleting the file and its `init.lua` line removes the feature

## Naming

- `name` in `snake_case`
- `title` in CMOS 18 title case, the rule nvim's keymap descs follow (`nvim/.config/nvim/docs/conventions/keymaps.md`, Titles)
- a `description` when the title leaves out what the action does

## Errors

A server call returns `result, err`. Raise a non-nil `err` with `error(err, 0)`, which shows Rex's message without a Lua file position.

## Server and client calls

An action reaches Rex through server calls (`rex.call`, `rex.block.call`, `rex.session.*`) or client actions: the app's `client.*`, `pane.*` and `session.*` actions (`pane.send_key`, `pane.close`, `session.new`), which a binding names or `rex.client.queue` asks for. The app's `session.*` actions are not the `rex.session.*` server calls. From the CLI, a client action needs Remote Control (Settings > General > Client Info), and it runs in the user's app.

So build an action on server calls wherever one exists, which `rex do` can test against a probe session ([testing.md](../testing.md)): `rex.block.call('com.superlogical.terminal', 'write' | 'process', ...)`, `rex.session.focus_direction`, `rex.call('block.close', ...)`.

A binding can name a block method itself, with the method's arguments as its args (`com.superlogical.terminal.write` with `{ data = ... }`), so an action that would only forward to one is not needed.
