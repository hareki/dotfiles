## AI Assistant Guidelines — Personal Dotfiles

Declarative system config managed via GNU Stow. Each top-level directory mirrors `$HOME`. Use `sync-d <module>` (or `stow <module>`) from repo root to symlink.

### Structure & Sub-Module Documentation

```
nvim/   → ~/.config/nvim     # Detailed: nvim/.config/nvim/.github/copilot-instructions.md
zsh/    → ~/.config/zsh      # Detailed: zsh/.config/zsh/.github/copilot-instructions.md
tmux/   → ~/.tmux* & ~/.config/tmux  # Detailed: tmux/.github/copilot-instructions.md
ghostty/ mise/ lazygit/ atuin/ → ~/.config/{tool}
```

**For complex changes in Neovim, ZSH, or tmux, read their sub-module docs first.**

### Core Principles

1. **Minimal, surgical edits** — no bulky frameworks or speculative refactors
2. **No hardcoded paths** — use `$HOME`, `$XDG_CONFIG_HOME`
3. **Theme cohesion** — Catppuccin Mocha everywhere (Neovim, tmux, Ghostty, lazygit, atuin)
4. **Performance first** — preserve lazy loading patterns in all tools

### Quick Reference

| Tool   | File Pattern                                                               | Key Conventions                                                                            |
| ------ | -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Neovim | `lua/plugins/{ai,coding,editor,formatting,lsp,treesitter,ui}/<plugin>.lua` | `popup_config()` for sizing; `Catppuccin()` for highlights; `desc` in keymaps (Title Case) |
| ZSH    | `functions/<name>` (one function per file, autoloaded)                     | Use `_evalcache` for expensive init; ~110ms startup budget                                 |
| tmux   | `tmux.options.conf`, `tmux.keymaps.conf`, `plugins/tmux.<name>.conf`       | Prefix is `M-d` (Alt+d), NOT `C-b`                                                         |
| mise   | `config.toml` under `[tools]`                                              | Prefer stable semver; PATH in `.zshenv`/`.zshrc` only                                      |

### Adding New Components

**Neovim plugin**: Create `lua/plugins/<category>/<plugin>.lua` returning spec table

```lua
return {
  Catppuccin(function(p) return { MyHl = { fg = p.blue } } end), -- optional
  { 'author/plugin', opts = {...}, keys = { { '<leader>x', ..., desc = 'Do Thing' } } },
}
```

**ZSH function**: Create `zsh/.config/zsh/functions/<name>` (autoload handles it)

```zsh
#!/bin/zsh
# myfn - Description
myfn() {
  local choice=$(cmd | fzf-tmux -p --reverse -w 60% -h 50%) || return 0
  [[ -z $choice ]] && return 0
  # ...
}
```

**tmux plugin**: Add `set -g @plugin 'author/repo'` in `.tmux.conf`, create `plugins/tmux.<name>.conf`, source it

### Cross-Tool Keybinding Harmony

Ghostty → tmux → Neovim: `cmd+<key>` emits escape sequences. Verify no collisions with:

- tmux: `M-d` prefix, `M-m/n/e/i` navigation, `M-t` floater
- Neovim: `<A-key>` bindings, `<leader>` commands

### Anti-Patterns

- ❌ Merging multiple plugin specs into one file
- ❌ Hardcoding absolute paths
- ❌ Heavy init without `_evalcache` in ZSH
- ❌ Removing "fork" comments or upstream links
- ❌ Assuming tmux prefix `C-b`

### When Uncertain

Outline keybinding flow across tools before implementing. Request confirmation for structural changes.
