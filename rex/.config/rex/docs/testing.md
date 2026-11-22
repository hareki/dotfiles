# Testing

Run these from `~/.config/rex`.

## Checks

- **Format**: `stylua --check .`
- **Load**: `rex config check` loads `init.lua` and counts its bindings and actions
- **Reload**: `rex config reload`
- **Bindings**: `rex keymap` lists the bindings the server loaded, and checks no action name or argument. Given the app's actions as its request, it warns about an unknown action and a bad argument to a custom action or block method, though not to a client action: `rex -C <client label> actions --json | jq -c '{actions: [.actions[] | {name}]}' | rex keymap --request -` (`rex client list` names the label). A warning leaves the exit status 0, so read the output. It leaves out the app's default shortcuts ([Shadowed defaults](conventions/keys.md#shadowed-defaults))

## Live tests

Run every live test in a probe session, never one in use:

- `rex new Probe --json -- <cmd>` makes a session without switching the app to it
- `rex do init.lua --action <name> -s <session> -b <block> key=value` (JSON args: `--args '{"direction":"left"}'`) runs a custom action from the working file, before any reload
- `rex do com.superlogical.terminal.write -s S -b B --args '{"data":"\u001b[1;6P"}'` writes the bytes a [raw-byte binding](conventions/keys.md#raw-bytes) sends
- `rex split -s S -b B --focus=false --shell=none -- /bin/cat -v` adds a pane that prints the bytes it gets
- `rex capture -s S -b B --trim` reads a pane
- `rex session inspect S --json | jq '.windows[0].focused_block_id'` shows where focus went
- `rex kill S` removes the session

## Untested live

Actions that queue `client.tab.close`, `client.close` or `client.setting.*` go to the user's one app client even from `rex do`, so a probe session does not contain them. Check them by reading, and by `defaults read com.superlogical.rex` after the user runs them ([Stored values](conventions/settings.md#stored-values)).
