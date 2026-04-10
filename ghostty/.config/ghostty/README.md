## My Personal Ghostty Config

Catppuccin Mocha-themed terminal config with heavy keybinding remaps for seamless tmux + Neovim workflows.

### Core Ideas

- Catppuccin Mocha theme with hidden macOS title bar
- Font: [Maple Mono NF](https://github.com/subframe7536/maple-font) (SemiBold, 20.5pt) with ligatures
- `Cmd` key remapped extensively to send escape sequences for tmux, Neovim, and zsh integration
- Shell integration: zsh with `no-cursor` (avoids conflicts with zsh vi-mode)
- Copy-on-select enabled

### Config Structure

```
.config/ghostty/
├── config                      # Main config: theme, font, shell, keybindings
└── shaders/
    └── cursor_trail.glsl       # Optional cursor trail effect (disabled by default)
```
