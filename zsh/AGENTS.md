# AGENTS.md

This file provides guidance to AI coding agents (e.g. Claude Code) when working with code in this repository.

## Architecture

This is a zsh dotfiles configuration targeting macOS with Homebrew. Files are deployed to `$HOME` via GNU stow using the `sync-dots` function (e.g., `sync-dots zsh`). Root-level package metadata (AGENTS.md, CLAUDE.md, README.md, assets) is excluded by root-anchored patterns in `stow/.stow-global-ignore`.

### Sourcing Order

```
.zshenv  (all shells)
  => zcompile .zshrc if stale (interactive shells only)
  => XDG_CONFIG_HOME, EDITOR, VISUAL, EZA_CONFIG_DIR, CLOUDSDK_PYTHON, API keys (from macOS keychain; skipped when inherited from a parent shell)
  => aliases needed in non-interactive shells (eza, fdt, gtimeout-wrapped fd)
  => PATH: typeset -U, then user_path prepended (~/.local/bin/shims, ~/.local/opt/bin, mise shims, ~/.local/bin, Homebrew, then the gcloud SDK bin for `gcloud components` binaries)

.zprofile  (login shells, right after /etc/zprofile)
  => re-apply user_path (path_helper moved the system dirs in front; covers non-interactive `zsh -lc` too)

.zshrc  (interactive shells)
  => emit beam cursor (override Neovim :terminal block cursor)
  => load p10k instant prompt cache
  => zmodload zprof if $ZSH_DEBUGRC
  => ~/.p10k.zsh (prompt config)
  => plugins.zsh (Antidote plugin manager, local _evalcache)
  => brew shellenv (via evalcache)
  => re-apply user_path (brew shellenv prepends Homebrew)
  => config modules in order: aliases, vi-mode, keymaps, options, evals, tty-guard
  => autoload functions from .config/zsh/functions/
  => put .config/zsh/compdefs/ on fpath (compinit picks up their `#compdef` tags)
```

The sourcing order of config modules matters: later files depend on earlier ones (e.g., keymaps overrides vi-mode bindings, evals runs tool init that needs PATH set up earlier).

- `options.zsh` holds interactive-only settings (`REPOS_DIR`/`STOW_REPO`, `PROMPT_EOL_MARK`) and the Catppuccin `FZF_DEFAULT_OPTS` / `_ZO_FZF_OPTS`. History settings come from omz's `lib/history.zsh`.
- `evals.zsh` runs tool init via `_evalcache`: zoxide, atuin, and `wt` (worktrunk); zsh-patina (syntax highlighter) is a plain `eval` because evalcache is unreliable for it.
- `tty-guard.zsh` is a `sched`-driven self-heal for the tty being put back into cooked mode while zle is reading the line (Node.js restores its startup termios on exit, even from a background process group): one `stty -g` per idle 2s tick, an empty `zle -M` to force `zsetterm` when icanon/echo are set.

### Plugin Management

Plugins are declared in `.zplugins` and managed by **Antidote**. Antidote statically generates a bundled file (`.zplugins.bundled.zsh`) that is only regenerated when `.zplugins` changes. Many plugins use `kind:defer` for deferred loading.

### Performance Patterns

- **evalcache**: A small local `_evalcache` in `plugins.zsh` wraps expensive `eval "$(command)"` calls (brew shellenv, zoxide, atuin, wt); output cached and zcompiled in `~/.cache/.zsh-evalcache/`, invalidated by `_evalcache_clear` (`yay` and `build` call it after updating tools).
- **mise**: not activated at runtime; it runs purely via shims prepended to `PATH` in `.zshenv`. A shim costs ~50ms per call (~90ms for a tool installed in mise but inactive in the current directory, e.g. claudecode.nvim's pinned fzf/neovim outside that project), so hot paths bypass it:
  - `build` installs into `~/.local/opt/bin` (`CARGO_INSTALL_ROOT`/`GOBIN`), which `user_path` puts ahead of the mise shims. Left in the toolchains' own dirs (`~/.cargo/bin`, mise's versioned go bin), atuin would pay the shim cost at every startup and before every command.
  - fzf-tab runs `/opt/homebrew/bin/fzf` directly (`fzf-command` zstyle).
  - `CLOUDSDK_PYTHON` points gcloud/bq/gsutil at the gcloud-cli cask's python@3.14. Unset, the SDK's wrapper probes for a python and then runs it, both through the shims: ~185ms => ~60ms per TAB. Bump it with the cask's python dependency (a stale path fails the `-x` check and falls back to the probe).
- **gcloud completion**: the SDK's bash-style `completion.zsh.inc`, which its installer sources from `.zshrc` (~3ms), is sourced by `compdefs/_gcloud` on the first TAB instead. Its `complete` calls re-register gcloud/gsutil/bq with `_bash_complete`, so later TABs skip `_gcloud`. `_bash_complete` runs the SDK's functions in a `$(compgen ...)` subshell, so bq's `bq_COMMANDS` cache never survives and every `bq` TAB re-runs `bq help` (~0.4s). Homebrew's `site-functions/_google_cloud_sdk` lacks a `#compdef` line, so compinit ignores it.
- **use-omz startup forks**: `plugins.zsh` presets `$ZSH` (otherwise a `$(antidote path ...)` subshell, ~15ms) and exports `SHORT_HOST` so child shells skip use-omz's `scutil` fork.
- **zsh-autosuggestions**: `ZSH_AUTOSUGGEST_MANUAL_REBIND` wraps the widgets once, when the plugin loads, instead of re-binding ~600 of them every precmd. `.zplugins` must therefore load it after every other widget-defining plugin (fzf-tab), since zsh-defer runs the precmd hooks after each deferred plugin.
- **zcompile**: `.zshrc` is precompiled to bytecode in `.zshenv`. Manual recompile: `compz` alias.
- **Autoload**: Functions in `.config/zsh/functions/` are registered via `autoload -Uz` and only loaded on first call.
- **Antidote zcompile**: All bundled plugins are zcompiled (`zstyle ':antidote:bundle:*' zcompile 'yes'`).
- **OSC 7 cwd reporting**: omz's `omz_termsupport_cwd` forks two subshells per prompt to URL-encode `$PWD`; a wrapper at the end of `plugins.zsh` caches the escape sequence until `$PWD` changes and re-emits the cached one each prompt (still every prompt, so the terminal's recorded cwd survives `reset` and tmux reattach).
- **compinit**: `use-omz` defers `compinit` to the first `precmd`, which is why `.zshrc` can still add to `fpath`. Its `$ZSH_COMPDUMP` cache holds only the `command => function` map, and is rebuilt when `fpath` changes or when the _number_ of `_*` files in `fpath` changes. A full rebuild costs ~120ms, so it is deliberately not forced on every compdef edit. See the stale-dump note under Conventions.

## Common Commands

```bash
profile               # Profile zsh startup time
compz                 # Recompile .zshrc to bytecode
sync-dots zsh         # Deploy zsh config via stow
yay                   # Update all package managers (brew, antidote, mise, tpm)
build <target>        # Build a local tool from source into ~/.local/opt/bin (atuin, eza, lazygit, television, worktrunk; tmux goes to /usr/local)
cts                   # Toggle git skip-worktree on claude-code settings.json (model/effort churn)
ff                    # fastfetch with buffered output
```

## Conventions

- New utility functions go in `.config/zsh/functions/` as standalone files (one function per file, filename = function name, no `.zsh` extension, since `autoload` looks the file up by function name). They are autoloaded automatically.
- All custom completions go in `.config/zsh/compdefs/`, one file per command named `_<command>` (e.g. `_build`, `_tv`) whose first line is `#compdef <command>`. This covers both the autoloaded functions above and external commands. The file body _is_ the completion function, so it needs no wrapper and no trailing `compdef` call. The directory is on `fpath`, so compinit registers the tag and autoloads the body on first use. A command family may share one file, and a vendor script meant for `.zshrc` gets a compdef that sources it on first use (both: `_gcloud`).
- **Stale completion dump.** `$ZSH_COMPDUMP` caches only the `command => function` mapping, and `compinit` regenerates it only when the _number_ of `_*` files in `fpath` changes. So:
  - Picked up on the next shell, no action needed: editing a compdef's body (bodies are autoloaded from `fpath` at completion time, never cached), adding a compdef, deleting one.
  - Goes **stale**, since the file count is unchanged: renaming a compdef file, or editing its `#compdef` line. The old command keeps resolving to a function file that no longer exists. Same for same-count renames in third-party `fpath` dirs (homebrew site-functions, `$ZSH_CACHE_DIR/completions`).
  - Fix: `rm $ZSH_COMPDUMP $ZSH_COMPDUMP.zwc`, then start a new shell.
- Aliases for non-interactive shells go in `.zshenv`; all others go in `.config/zsh/aliases.zsh`.
- Interactive env vars / history overrides / fzf options go in `.config/zsh/options.zsh`. Tool init (`zoxide`, `atuin`, `wt`, `zsh-patina`) goes in `.config/zsh/evals.zsh`.
- Plugin configuration (zstyles, env vars) goes in `.config/zsh/plugins.zsh`, before the bundle is sourced. Overrides of what the bundle itself sets go after it: wrappers of a plugin function (e.g. `omz_termsupport_cwd`, since the original must already exist to be copied) and zstyles omz sets under a more specific pattern (e.g. its `':completion:*:*:*:*:*' menu select`, which outranks any `':completion:*'` style).
- Color theme is **Catppuccin Mocha** throughout (fzf, zsh-patina syntax highlighting, eza, etc.).
- Paths assume Homebrew at `/opt/homebrew/`.
