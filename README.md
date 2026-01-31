# Personal Dotfiles

> Declarative, modular configs managed via [GNU Stow](https://www.gnu.org/software/stow/). Catppuccin Mocha everything. ☕

Each top‑level directory mirrors its destination under `$HOME` (e.g. `nvim/` → `~/.config/nvim`, `zsh/` → shell startup, `tmux/` → `~/.tmux*`).

## Usage

I wrote a tiny wrapper called `sync-d` (autoloaded from `zsh/.config/zsh/functions/sync-d`) that enforces repo root + target path, with tab‑completion:

```bash
# Single module
sync-d nvim

# Multiple modules
sync-d zsh tmux ghostty lazygit mise atuin

# Fallback (plain stow)
cd "$STOW_REPO" && stow nvim
```

## Highlights

| Module      | What's Inside                                                                                                                                                           |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Neovim**  | From‑scratch Lua config. One plugin per file (`lua/plugins/**`), shared UI primitives (`lua/utils/ui.lua`) for consistent popup geometry. Aggressive lazy‑loading.      |
| **ZSH**     | ~110ms cold start via Antidote static bundling, `evalcache`, `zcompile`, autoloaded functions. Clean layering: plugins → topic configs (aliases, keymaps, fzf, zoxide). |
| **tmux**    | Layered setup: `.tmux.conf` wires plugins, then splits into `tmux.options.conf` and `tmux.keymaps.conf`. Prefix is `M-d` (Alt+d).                                       |
| **Ghostty** | Keybindings emit escape sequences consumed by tmux/ZSH/Neovim for seamless cross‑tool cohesion.                                                                         |

**Theme**: Catppuccin Mocha across Neovim, tmux, Ghostty, lazygit, atuin, and more.
