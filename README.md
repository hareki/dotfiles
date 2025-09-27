## Personal Dotfiles

Declarative, modular config managed via GNU Stow. Each top‑level directory mirrors its destination under $HOME (e.g. `nvim/` -> `~/.config/nvim`, `zsh/` -> shell startup, `tmux/` -> `~/.tmux*`, etc.). I created a tiny wrapper function around `stow` called `sync-d` (autoloaded from `zsh/.config/zsh/functions/sync-d`) which enforces the repo root and target path (with autocompletion!).

Usage (one directory per call):

```bash
# Single module
sync-d nvim

# Batch
for m in zsh tmux ghostty lazygit mise atuin; do sync-d "$m"; done

# Fallback (manual stow)
cd "$STOW_REPO" && stow nvim
```

### Highlights
- **Neovim (`nvim/`)**: From‑scratch Lua config. One plugin per file (`lua/plugins/**`) + shared UI primitives (`lua/utils/ui.lua`) for consistent floating window geometry. Aggressive lazy‑loading keeps startup fast.
- **ZSH (`zsh/`)**: ~110ms cold start using Antidote static bundling, `evalcache`, `zcompile`, autoloaded functions (`.config/zsh/functions/*`). Clean layering: plugins, then small topic configs (aliases, keymaps, fzf, zoxide).
- **tmux (`tmux/`)**: Layered config: `.tmux.conf` only wires plugins + splits options (`tmux.options.conf`) and keymaps (`tmux.keymaps.conf`). Prefix remapped to Alt+d (`M-d`).
- **Cross‑tool cohesion**: Ghostty keybindings emit escape sequences consumed by tmux/ZSH/Neovim.
 - **Theme**: Catppuccin Mocha whenever possible (Neovim, tmux, Ghostty, lazygit, atuin).