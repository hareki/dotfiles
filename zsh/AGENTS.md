# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

This is a zsh dotfiles configuration targeting macOS with Homebrew. Files are deployed to `$HOME` via GNU stow using the `sync-d` function (e.g., `sync-d zsh`).

### Sourcing Order

```
.zshenv  (all shells)
  → zcompile .zshrc if stale
  → XDG_CONFIG_HOME, EDITOR, VISUAL
  → aliases needed in non-interactive shells (eza, fd)
  → mise shims in PATH

.zshrc  (interactive shells)
  → p10k prompt config
  → history settings
  → plugins.zsh (Antidote plugin manager)
  → brew shellenv (via evalcache)
  → config modules in order: aliases, vi-mode, compdef, keymaps, fzf, zoxide, env
  → autoload functions from .config/zsh/functions/
  → mise activate, zoxide init, atuin init (via evalcache where possible)
```

The sourcing order of config modules matters — later files depend on earlier ones (e.g., keymaps overrides vi-mode bindings, fzf depends on plugins being loaded).

### Plugin Management

Plugins are declared in `.zplugins` and managed by **Antidote**. Antidote statically generates a bundled file (`.zplugins.bundled.zsh`) that is only regenerated when `.zplugins` changes. Many plugins use `kind:defer` for deferred loading.

### Performance Patterns

- **evalcache**: Wraps expensive `eval "$(command)"` calls; cached in `~/.cache/.zsh-evalcache/`. Note: `mise activate` cannot use evalcache (see comment in .zshrc).
- **zcompile**: `.zshrc` is precompiled to bytecode in `.zshenv`. Manual recompile: `compz` alias.
- **Autoload**: Functions in `.config/zsh/functions/` are registered via `autoload -Uz` and only loaded on first call.
- **Antidote zcompile**: All bundled plugins are zcompiled (`zstyle ':antidote:bundle:*' zcompile 'yes'`).

## Common Commands

```bash
profile               # Profile zsh startup time
compz                 # Recompile .zshrc to bytecode
sync-d zsh            # Deploy zsh config via stow
yay                   # Update all package managers (brew, antidote, mise, tpm, npm, gem)
```

## Conventions

- New utility functions go in `.config/zsh/functions/` as standalone files (one function per file, filename = function name, no `.zsh` extension). They are autoloaded automatically.
- Aliases for non-interactive shells go in `.zshenv`; all others go in `.config/zsh/aliases.zsh`.
- Plugin configuration (zstyles, env vars) goes in `.config/zsh/plugins.zsh`, before the bundle is sourced.
- Color theme is **Catppuccin Mocha** throughout (fzf, syntax highlighting, etc.).
- Paths assume Homebrew at `/opt/homebrew/`.
