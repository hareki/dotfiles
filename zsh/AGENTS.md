# AGENTS.md

This file provides guidance to AI coding agents (e.g. Claude Code) when working with code in this repository.

## Architecture

This is a zsh dotfiles configuration targeting macOS with Homebrew. Files are deployed to `$HOME` via GNU stow using the `sync-dots` function (e.g., `sync-dots zsh`). Root-level package metadata (AGENTS.md, CLAUDE.md, README.md, assets) is excluded by root-anchored patterns in `stow/.stow-global-ignore`.

### Sourcing Order

```
.zshenv  (all shells)
  → zcompile .zshrc if stale
  → XDG_CONFIG_HOME, EDITOR, VISUAL, API keys (from macOS keychain; skipped when inherited from a parent shell)
  → aliases needed in non-interactive shells (eza, fdt, gtimeout-wrapped fd)
  → PATH: typeset -U, then shim_paths (~/.local/bin/shims, mise shims) + ~/.local/bin

.zshrc  (interactive shells)
  → emit beam cursor (override Neovim :terminal block cursor)
  → load p10k instant prompt cache
  → zmodload zprof if $ZSH_DEBUGRC
  → ~/.p10k.zsh (prompt config)
  → plugins.zsh (Antidote plugin manager, local _evalcache)
  → brew shellenv (via evalcache)
  → re-prepend shim_paths (brew shellenv runs path_helper, which reorders PATH)
  → config modules in order: aliases, vi-mode, keymaps, options, evals
  → autoload functions from .config/zsh/functions/
  → put .config/zsh/compdefs/ on fpath (compinit picks up their `#compdef` tags)
```

The sourcing order of config modules matters — later files depend on earlier ones (e.g., keymaps overrides vi-mode bindings, evals runs tool init that needs PATH set up earlier).

- `options.zsh` holds interactive-only env vars (history, `REPOS_DIR`/`STOW_REPO`, eza/tealdeer dirs, `DYLD_FALLBACK_LIBRARY_PATH`, `PROMPT_EOL_MARK`) and the Catppuccin `FZF_DEFAULT_OPTS` / `_ZO_FZF_OPTS`.
- `evals.zsh` runs tool init via `_evalcache`: zoxide, atuin, and `wt` (worktrunk); zsh-patina (syntax highlighter) is a plain `eval` because evalcache is unreliable for it.

### Plugin Management

Plugins are declared in `.zplugins` and managed by **Antidote**. Antidote statically generates a bundled file (`.zplugins.bundled.zsh`) that is only regenerated when `.zplugins` changes. Many plugins use `kind:defer` for deferred loading.

### Performance Patterns

- **evalcache**: A small local `_evalcache` in `plugins.zsh` wraps expensive `eval "$(command)"` calls (brew shellenv, zoxide, atuin, wt); output cached and zcompiled in `~/.cache/.zsh-evalcache/`, invalidated by deleting the cache file.
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
build <target>        # Build a local tool from source (atuin, eza, lazygit, television, tmux, worktrunk)
cts                   # Toggle git skip-worktree on claude-code settings.json (model/effort churn)
ff                    # fastfetch with buffered output
```

## Conventions

- New utility functions go in `.config/zsh/functions/` as standalone files (one function per file, filename = function name, no `.zsh` extension, since `autoload` looks the file up by function name). They are autoloaded automatically.
- All custom completions go in `.config/zsh/compdefs/`, one file per command named `_<command>` (e.g. `_build`, `_tv`) whose first line is `#compdef <command>`. This covers both the autoloaded functions above and external commands. The file body *is* the completion function, so it needs no wrapper and no trailing `compdef` call. The directory is on `fpath`, so compinit registers the tag and autoloads the body on first use.
- **Stale completion dump.** `$ZSH_COMPDUMP` caches only the `command => function` mapping, and `compinit` regenerates it only when the *number* of `_*` files in `fpath` changes. So:
  - Picked up on the next shell, no action needed: editing a compdef's body (bodies are autoloaded from `fpath` at completion time, never cached), adding a compdef, deleting one.
  - Goes **stale**, since the file count is unchanged: renaming a compdef file, or editing its `#compdef` line. The old command keeps resolving to a function file that no longer exists. Same for same-count renames in third-party `fpath` dirs (homebrew site-functions, `$ZSH_CACHE_DIR/completions`).
  - Fix: `rm $ZSH_COMPDUMP $ZSH_COMPDUMP.zwc`, then start a new shell.
- Aliases for non-interactive shells go in `.zshenv`; all others go in `.config/zsh/aliases.zsh`.
- Interactive env vars / history / fzf options go in `.config/zsh/options.zsh`. Tool init (`zoxide`, `atuin`, `wt`, `zsh-patina`) goes in `.config/zsh/evals.zsh`.
- Plugin configuration (zstyles, env vars) goes in `.config/zsh/plugins.zsh`, before the bundle is sourced.
- Color theme is **Catppuccin Mocha** throughout (fzf, zsh-patina syntax highlighting, eza, etc.).
- Paths assume Homebrew at `/opt/homebrew/`.
