# AGENTS.md

This file provides guidance to AI coding agents (e.g. Claude Code) when working with code in this repository.

## Architecture

This is a zsh dotfiles configuration targeting macOS with Homebrew. Files are deployed to `$HOME` via GNU stow using the `sync-dots` function (e.g., `sync-d zsh`).

### Sourcing Order

```
.zshenv  (all shells)
  → zcompile .zshrc if stale
  → XDG_CONFIG_HOME, EDITOR, VISUAL, MERCURY_API_KEY (from macOS keychain)
  → aliases needed in non-interactive shells (eza, fdt, gtimeout-wrapped fd)
  → PATH: ~/.local/bin/shims, ~/.local/bin, mise shims

.zshrc  (interactive shells)
  → emit beam cursor (override Neovim :terminal block cursor)
  → load p10k instant prompt cache
  → zmodload zprof if $ZSH_DEBUGRC
  → ~/.p10k.zsh (prompt config)
  → plugins.zsh (Antidote plugin manager)
  → brew shellenv (via evalcache)
  → config modules in order: aliases, vi-mode, keymaps, options, evalcache
  → autoload functions from .config/zsh/functions/
  → put .config/zsh/compdefs/ on fpath (compinit picks up their `#compdef` tags)
```

The sourcing order of config modules matters — later files depend on earlier ones (e.g., keymaps overrides vi-mode bindings, evalcache runs tool init that needs PATH set up earlier).

- `options.zsh` holds interactive-only env vars (history, `STOW_REPO`, eza/tealdeer dirs, `PROMPT_EOL_MARK`) and the Catppuccin `FZF_DEFAULT_OPTS` / `_ZO_FZF_OPTS`.
- `evalcache.zsh` runs tool init via `_evalcache`: zoxide, atuin, and zsh-patina (syntax highlighter).

### Plugin Management

Plugins are declared in `.zplugins` and managed by **Antidote**. Antidote statically generates a bundled file (`.zplugins.bundled.zsh`) that is only regenerated when `.zplugins` changes. Many plugins use `kind:defer` for deferred loading.

### Performance Patterns

- **evalcache**: Wraps expensive `eval "$(command)"` calls (brew shellenv, zoxide, atuin, zsh-patina); cached in `~/.cache/.zsh-evalcache/`.
- **mise**: not activated at runtime — it runs purely via shims prepended to `PATH` in `.zshenv`.
- **zcompile**: `.zshrc` is precompiled to bytecode in `.zshenv`. Manual recompile: `compz` alias.
- **Autoload**: Functions in `.config/zsh/functions/` are registered via `autoload -Uz` and only loaded on first call.
- **Antidote zcompile**: All bundled plugins are zcompiled (`zstyle ':antidote:bundle:*' zcompile 'yes'`).
- **compinit**: `use-omz` defers `compinit` to the first `precmd`, which is why `.zshrc` can still add to `fpath`. Its `$ZSH_COMPDUMP` cache holds only the `command => function` map, and is rebuilt when `fpath` changes or when the *number* of `_*` files in `fpath` changes. A full rebuild costs ~120ms, so it is deliberately not forced on every compdef edit. See the stale-dump note under Conventions.

## Common Commands

```bash
profile               # Profile zsh startup time
compz                 # Recompile .zshrc to bytecode
sync-dots zsh         # Deploy zsh config via stow
yay                   # Update all package managers (brew, antidote, mise, tpm)
build <target>        # Build a local tool from source (atuin, eza, lazygit, television, tmux)
```

## Conventions

- New utility functions go in `.config/zsh/functions/` as standalone files (one function per file, filename = function name, no `.zsh` extension, since `autoload` looks the file up by function name). They are autoloaded automatically.
- All custom completions go in `.config/zsh/compdefs/`, one file per command named `_<command>` (e.g. `_build`, `_tv`) whose first line is `#compdef <command>`. This covers both the autoloaded functions above and external commands. The file body *is* the completion function, so it needs no wrapper and no trailing `compdef` call. The directory is on `fpath`, so compinit registers the tag and autoloads the body on first use.
- **Stale completion dump.** `$ZSH_COMPDUMP` caches only the `command => function` mapping, and `compinit` regenerates it only when the *number* of `_*` files in `fpath` changes. So:
  - Picked up on the next shell, no action needed: editing a compdef's body (bodies are autoloaded from `fpath` at completion time, never cached), adding a compdef, deleting one.
  - Goes **stale**, since the file count is unchanged: renaming a compdef file, or editing its `#compdef` line. The old command keeps resolving to a function file that no longer exists. Same for same-count renames in third-party `fpath` dirs (homebrew site-functions, `$ZSH_CACHE_DIR/completions`).
  - Fix: `rm $ZSH_COMPDUMP $ZSH_COMPDUMP.zwc`, then start a new shell.
- Aliases for non-interactive shells go in `.zshenv`; all others go in `.config/zsh/aliases.zsh`.
- Interactive env vars / history / fzf options go in `.config/zsh/options.zsh`. Tool init (`zoxide`, `atuin`, `zsh-patina`) goes in `.config/zsh/evalcache.zsh`.
- Plugin configuration (zstyles, env vars) goes in `.config/zsh/plugins.zsh`, before the bundle is sourced.
- Color theme is **Catppuccin Mocha** throughout (fzf, zsh-patina syntax highlighting, eza, etc.).
- Paths assume Homebrew at `/opt/homebrew/`.
