# Keys

Where a binding goes, how a key reaches the program in the pane, and which of the app's own shortcuts a binding takes over.

## Where a binding goes

- `config/keymaps.lua` binds Rex's built-in actions
- `features/program-keys.lua` binds the keys sent to the program in the pane: alt keys ([Cmd => Alt](#cmd--alt)) and raw bytes ([Raw bytes](#raw-bytes))
- A key that runs a custom action is bound in that action's feature file, `features/<name>.lua` ([Actions](actions.md))
- **Sent keys**: every key a binding sends to the program in the pane carries a trailing comment naming the program and what the key does there (`'f', -- zsh: atuin search`), since nothing in this directory shows what reads it

## Cmd => Alt

A cmd key reaches only a program that turned on the kitty keyboard protocol (`\27[<codepoint>;9u`, `10` with shift, which nvim maps as `<D-s>`). zsh gets no bytes for it, nvim's `:terminal` drops the modifier and types the bare letter, and legacy `alt+shift+s` arrives as `\es`, shift lost.

Alt is the one modifier that passes zsh, nvim's terminal, fzf and Claude Code, so a new cmd key for a program goes in `ALT_KEYS` (`features/program-keys.lua`) and the program listens for the alt key. Only `shift+cmd+s` and `shift+cmd+w` go as the cmd key itself (a Lua function that returns `false`), for nvim alone: a function binding keeps the app's own shortcut off it (`rex keymap` lists it as `client.key.forward`), and the false return hands the pane the key as a press would send it. A `pane.send_key` binding that sends its own key reaches no pane: a press of it gave nvim nothing (2026-11-23).

## Raw bytes

A binding sends bytes by naming the terminal's `write` block method, `com.superlogical.terminal.write` with `{ data = '...' }`, which writes them to the focused pane as they are.

`pane.send_key` encodes a key as the terminal would (`ctrl+shift+f1` reaches nvim as `<C-S-F1>`), while the same key written as bytes reaches it as another (`\27[1;6P` is `<F37>`). Pick the form that lands on the key the program maps, and say which in the comment.

## Shadowed defaults

The app's default shortcuts (`cmd+f`, `cmd+w`, `shift+cmd+w`, `ctrl+tab`) are a layer `rex keymap` does not list, and a config binding shadows them. They are listed only on the Rex docs page [`/rex/docs/reference/mac-actions`](https://www.superlogical.com/rex/docs/reference/mac-actions).

Check that page before binding a key. A default may stay shadowed, since its action stays in the command palette. To keep a key for one, bind it elsewhere with a comment naming the key it lost (`cmd+d>/` for find, `cmd+d>x` for close).

## Pane navigation

`cmd+m/n/e/i` is one grid across Rex panes and nvim windows. `navigate` (`features/pane-navigation.lua`) writes `\27` plus the letter (alt+m/n/e/i) when the pane's foreground process is in `NAVIGATES_ITSELF` (`process` returns `.foreground.name`, `nvim` even through the mise shim's exec), and nvim calls `rex focus <direction>` (the CLI acts on the session that holds the pane's `$REX_BLOCK`) from a window at its edge (`nvim/.config/nvim/lua/features/navigation/window-navigation/`).

## Files outside this config

These read the keys Rex sends, so change them with the binding:

- `features/pane-navigation.lua` and nvim's `features/navigation/window-navigation/` ([Pane navigation](#pane-navigation))
- `features/program-keys.lua` and the programs that listen for its keys: nvim's keymaps, `zsh/.config/zsh/keymaps.zsh`, Claude Code
