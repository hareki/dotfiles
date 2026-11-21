# Personal Dotfiles

> Declarative, modular configs managed via [GNU Stow](https://www.gnu.org/software/stow/). Catppuccin Mocha everything. ☕

Each top‑level directory mirrors its destination under `$HOME` (e.g. `nvim/` => `~/.config/nvim`, `zsh/` => shell startup, `rex/` => `~/.config/rex`).

## Usage

I wrote a tiny wrapper called `sync-dots` (autoloaded from `zsh/.config/zsh/functions/sync-dots`) that enforces repo root + target path, with tab‑completion:

```bash
# Single module
sync-dots nvim

# Multiple modules
sync-dots zsh rex ghostty lazygit mise atuin

# Every package directory in $STOW_REPO
sync-dots all

# Fallback (plain stow)
stow -d "$STOW_REPO" -t ~ nvim
```

## Highlights

- **[neovim](./nvim/.config/nvim/)**: From‑scratch Lua config. One plugin per file (`lua/{core,chrome,features}/**`), shared UI primitives (`lua/utils/ui/`) for consistent popup geometry. Aggressive lazy‑loading.
- **[zsh](./zsh/)**: ~45ms to the first prompt via Antidote static bundling, a local `_evalcache`, `zcompile`, autoloaded functions. Clean layering: plugins => topic configs (aliases, vi-mode, keymaps, options, evals, tty-guard).
- **[rex](./rex/.config/rex/)**: The terminal and multiplexer, configured in Lua. Each `Cmd` key sends what ZSH, Neovim and Claude Code listen for, and pane navigation is shared with Neovim. Prefix is `Cmd+d`.
- **[ghostty](./ghostty/.config/ghostty/)**: Keybindings emit escape sequences consumed by ZSH/Neovim for seamless cross‑tool cohesion.

**Theme**: Catppuccin Mocha across Neovim, Rex, Ghostty, lazygit, atuin, and more.
