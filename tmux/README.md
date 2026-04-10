## My Personal Tmux Config

**TPM**-managed config optimized for Neovim integration, vi-style copy mode, and image passthrough.

### Core Ideas

- Prefix key: `Alt-d`
- Vi keybindings in copy mode with system clipboard integration
- Seamless pane navigation shared with Neovim via [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)
- Catppuccin Mocha theme with customized status bar
- Image passthrough enabled for tools like [yazi](https://github.com/sxyazi/yazi) and [image.nvim](https://github.com/3rd/image.nvim)

### Plugins

| Plugin                                                                         | Purpose                                 |
| ------------------------------------------------------------------------------ | --------------------------------------- |
| [TPM](https://github.com/tmux-plugins/tpm)                                     | Plugin manager                          |
| [tmux-yank](https://github.com/tmux-plugins/tmux-yank)                         | System clipboard integration            |
| [tmux-catppuccin](https://github.com/catppuccin/tmux) (fork)                   | Catppuccin Mocha status bar and theming |
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) (fork) | Seamless Neovim ↔ tmux pane navigation  |

### Config Structure

```
.tmux.conf                              # Entry point — sources everything + TPM plugins
.config/tmux/
├── tmux.options.conf                   # Terminal, mouse, true color, image passthrough
├── tmux.keymaps.conf                   # All keybindings
└── plugins/
    ├── tmux.tmux-catppuccin.conf       # Theme: status bar layout, pane borders, icons
    ├── tmux.tmux-yank.conf             # Clipboard bindings
    └── tmux.vim-tmux-navigator.conf    # Pane navigation keys
```
