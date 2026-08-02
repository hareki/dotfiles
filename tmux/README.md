# My Personal Tmux Config

![image](./assets/docs/demo.png)

**TPM**-managed config optimized for Neovim integration, vi-style copy mode, and image passthrough.

## Core Ideas

- Prefix key: `Alt-d`
- Vi keybindings in copy mode with system clipboard integration
- Seamless pane navigation shared with Neovim via [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)
- Catppuccin Mocha theme with customized status bar
- Image passthrough enabled for tools like [yazi](https://github.com/sxyazi/yazi) and [snacks.image](https://github.com/folke/snacks.nvim/blob/main/docs/image.md)

## Plugins

| Plugin                                                                         | Purpose                                 |
| ------------------------------------------------------------------------------ | --------------------------------------- |
| [TPM](https://github.com/tmux-plugins/tpm)                                     | Plugin manager                          |
| [tmux-yank](https://github.com/tmux-plugins/tmux-yank)                         | System clipboard integration            |
| [tmux-catppuccin](https://github.com/catppuccin/tmux) (fork)                   | Catppuccin Mocha status bar and theming |
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)        | Seamless Neovim ↔ tmux pane navigation  |

## Config Structure

```
.config/tmux/
├── tmux.conf                  # Entry point: sources everything + TPM plugins
├── options.conf               # Terminal, mouse, true color, image passthrough
├── keymaps.conf               # All keybindings
├── typos.toml                 # typos-lsp allowlist (@thm_* palette vars)
└── plugins/
    ├── catppuccin.conf        # Theme: status bar layout, pane borders, icons
    ├── yank.conf              # Clipboard bindings
    └── vim-tmux-navigator.conf # Pane navigation keys
```

Plugins themselves are installed by TPM into `~/.tmux/plugins/` (pinned via
`TMUX_PLUGIN_MANAGER_PATH`); the `plugins/` directory here only holds their configs.

On a fresh machine, bootstrap TPM once, then install plugins with `prefix + I`:

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```
