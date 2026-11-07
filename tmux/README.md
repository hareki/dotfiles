# My Personal Tmux Config

![image](./assets/docs/demo.png)

**TPM**-managed config optimized for Neovim integration, vi-style copy mode, and image passthrough.

## Core Ideas

- Prefix key: `Alt-d`
- Vi keybindings in copy mode with system clipboard integration
- Seamless pane navigation shared with Neovim via [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)
- Catppuccin Mocha theme with customized status bar
- Image passthrough enabled for [snacks.image](https://github.com/folke/snacks.nvim/blob/main/docs/image.md)
- Manual snapshots with `tsave` / `trestore` (see [Snapshots](#snapshots))

## Plugins

- **[TPM](https://github.com/tmux-plugins/tpm)**: Plugin manager
- **[tmux-catppuccin](https://github.com/hareki/tmux-catppuccin)** (fork of [catppuccin/tmux](https://github.com/catppuccin/tmux)): Catppuccin Mocha status bar and theming
- **[tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)**: Session snapshots, taken by hand only (no tmux-continuum)
- **[vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)**: Seamless Neovim ↔ tmux pane navigation. Its tmux half is bound directly in `plugins/vim-tmux-navigator.conf` rather than loaded through TPM

The copy-mode yank keys need no plugin: tmux's `set-clipboard` sends each copy as OSC 52, and `copy-command` pipes it to `pbcopy`.

## Snapshots

The zsh functions `tsave` and `trestore` drive tmux-resurrect:

- **`tsave`**: snapshots every session, then quits each pane's nvim through its normal exit (so auto-session saves its session) and kills the server
  - **`-c`/`--continue`**: snapshot only, leaving nvim and tmux running, like resurrect's own `prefix C-s`
  - Nothing is quit or killed while an nvim holds work a kill would lose: unsaved buffers, a nested nvim in a terminal buffer, a suspended nvim, or one it can't reach. Pane nvims publish their RPC address as the `@nvim-server` pane option for this (nvim's `core/auto-session/utils.lua`)
  - From a pane nvim's terminal (`<A-t>`), it reruns itself from the tmux server so that nvim can quit too, and shows its report in view mode on that pane (`q` closes it)
- **`trestore [<id>]`**: restores a snapshot into a fresh server, from inside tmux or from a plain terminal
  - Without an id it restores `last`, the snapshot most recently saved or restored (also what `prefix C-r` restores)
  - Ids are the snapshot's date and time (`2026-11-04_20-15-30`); `trestore <TAB>` and `trestore --list` show them newest first
  - **`--force`**: restore into a server that already has panes (resurrect leaves those as they are)
- **Expiry**: `scripts/resurrect-prune.sh`, resurrect's post-save hook, deletes snapshots 3 days after their last save. The snapshot `last` pointed to before a save survives that save, so a stray save can't take the one you meant to restore
- **nvim relaunch**: nvim panes relaunch as bare `nvim` in nvim's directory, so auto-session reopens that directory's session. An `nvim <file>` pane comes back as its directory's session, not the file

## Config Structure

```
.config/tmux/
├── tmux.conf                  # Entry point: sources everything + TPM plugins
├── options.conf               # Terminal, mouse, true color, image passthrough
├── keymaps.conf               # Keybindings, except pane navigation
├── typos.toml                 # typos-lsp allowlist (@thm_* palette vars)
├── plugins/
│   ├── catppuccin.conf        # Theme: status bar layout, pane borders, icons, copy-mode and menu colors
│   ├── vim-tmux-navigator.conf # Pane navigation keys, shared with Neovim
│   └── resurrect.conf         # Snapshot dir, expiry hook, nvim relaunch
└── scripts/
    └── resurrect-prune.sh     # Expires snapshots 3 days after their last save
```

Plugins themselves are installed by TPM into `~/.tmux/plugins/` (pinned via
`TMUX_PLUGIN_MANAGER_PATH`); the `plugins/` directory here only holds their configs.

On a fresh machine, bootstrap TPM once, then install plugins with `prefix + I`:

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```
