# AGENTS.md

This file provides guidance to AI coding agents (e.g. Claude Code) when working with code in this repository.

## Architecture

This is a zsh dotfiles configuration targeting macOS with Homebrew. Files are deployed to `$HOME` via GNU stow using the `sync-dots` function (e.g., `sync-dots zsh`). Root-level package metadata (AGENTS.md, CLAUDE.md, README.md, assets) is excluded by root-anchored patterns in `stow/.stow-global-ignore`.

### Sourcing Order

```
.zshenv  (all shells)
  => XDG_CONFIG_HOME, EDITOR, VISUAL, EZA_CONFIG_DIR, CLOUDSDK_PYTHON, API keys (from macOS keychain; skipped when inherited from a parent shell)
  => a top-level login shell (SHLVL 1) sources /etc/zprofile (path_helper, LANG)
  => unsetopt global_rcs (zsh itself reads no other /etc rc)
  => PATH: typeset -U, then user_path prepended (~/.local/bin/shims, ~/.local/opt/bin, mise shims, ~/.local/bin, Homebrew, then the gcloud SDK bin for `gcloud components` binaries)

.zshrc  (interactive shells)
  => emit beam cursor (override Neovim :terminal block cursor)
  => load p10k instant prompt cache
  => zmodload zprof if $ZSH_DEBUGRC
  => ~/.p10k.zsh (prompt config)
  => plugins.zsh, in order:
     local _evalcache and the plugin options
     brew shellenv (via evalcache), then re-apply user_path (brew shellenv prepends Homebrew)
     put .config/zsh/{compdefs,functions}/ on fpath (compinit picks up the compdefs' `#compdef` tags)
     compinit, then the Antidote bundle, then omz's update check
     overrides of what the bundle set
  => config modules in order: aliases, vi-mode, keymaps, options, evals, tty-guard
  => autoload functions from .config/zsh/functions/
```

The sourcing order of config modules matters: later files depend on earlier ones (e.g., keymaps' plain `bindkey` calls only reach viins because vi-mode's `bindkey -v` has replaced omz's `bindkey -e` by then, and evals runs tool init that needs PATH set up earlier).

- `options.zsh` holds interactive-only settings (`REPOS_DIR`/`STOW_REPO`, `PROMPT_EOL_MARK`, plus `combining_chars` and `disable log` from the skipped `/etc/zshrc`) and the Catppuccin `FZF_DEFAULT_OPTS` / `_ZO_FZF_OPTS`. History settings come from omz's `lib/history.zsh`.
- `evals.zsh` runs tool init via `_evalcache`: zoxide (then backgrounds its hook), atuin (after minting its session ID, minus one init line, then resets the autosuggest strategy, see Performance Patterns), `wt` (worktrunk) and zsh-patina (syntax highlighter, after the daemon check described there).
- `tty-guard.zsh` is a `sched`-driven self-heal for the tty being put back into cooked mode while zle is reading the line (Node.js restores its startup termios on exit, even from a background process group): one `stty -g` per idle 2s tick, an empty `zle -M` to force `zsetterm` when icanon/echo are set.

### Plugin Management

Plugins are declared in `.zplugins` and managed by **Antidote**. Antidote statically generates a bundled file (`.zplugins.bundled.zsh`) that is only regenerated when `.zplugins` changes. Many plugins use `kind:defer` for deferred loading.

`.zplugins` lists only the omz lib files this config uses instead of all of `lib` (~2ms per shell), and omz's own loader isn't used either: `plugins.zsh` sets the `$ZSH` and `$ZSH_CACHE_DIR` that the libs and the updater read, and runs compinit and `tools/check_for_upgrade.sh` itself. Helpers from the other lib files (`omz`, `clipcopy`, `git_prompt_info`, ...) don't exist here, so a lib file that something starts to need has to be added to the list.

### Performance Patterns

- **evalcache**: A small local `_evalcache` in `plugins.zsh` wraps expensive `eval "$(command)"` calls (brew shellenv, zoxide, atuin, wt, zsh-patina); output cached and zcompiled in `~/.cache/.zsh-evalcache/`, invalidated by `_evalcache_clear` (`yay` and `build` call it after updating tools).
  - Its zprof time is the cached scripts' own code: the wrapper adds ~10µs over a bare `source`, which already loads the `.zwc`. Sourcing the `.zwc` directly fails (zsh parses it as text).
- **mise**: not activated at runtime; it runs purely via shims prepended to `PATH` in `.zshenv`. A shim costs ~25ms per call (~65ms for a tool installed in mise but inactive in the current directory, e.g. claudecode.nvim's pinned fzf/neovim outside that project), so hot paths bypass it:
  - `build` installs into `~/.local/opt/bin` (`CARGO_INSTALL_ROOT`/`GOBIN`), which `user_path` puts ahead of the mise shims. Left in the toolchains' own dirs (`~/.cargo/bin`, mise's versioned go bin), atuin would pay the shim cost at every startup and before every command.
  - fzf is a `build` target too (the hareki/fzf fork, which drops the blank column inside borders and adds the `--max-width` in fzf-tab's `fzf-flags`, an option a stock fzf rejects), so fzf-tab's plain `fzf` lookup lands there instead of the shim for claudecode.nvim's pinned fzf.
- **gcloud python**: `CLOUDSDK_PYTHON` points gcloud/bq/gsutil at an on-request python@3.13 (so `brew autoremove` leaves it alone). Unset, the SDK's wrapper first runs a python just to vet it (3.9-3.14, which rules out mise's): ~60ms => ~45ms per TAB. Any accepted python works, and a stale path fails the `-x` check and falls back to that probe.
- **gcloud completion**: the SDK's bash-style `completion.zsh.inc`, which its installer sources from `.zshrc` (~3ms), is sourced by `compdefs/_gcloud` on the first TAB instead. Its `complete` calls re-register gcloud/gsutil/bq with `_bash_complete`, so later TABs skip `_gcloud`. `_bash_complete` runs the SDK's functions in a `$(compgen ...)` subshell, so bq's `bq_COMMANDS` cache never survives and every `bq` TAB re-runs `bq help` (~0.4s). Homebrew's `site-functions/_google_cloud_sdk` lacks a `#compdef` line, so compinit ignores it.
- **p10k SSH probe**: p10k forks `who -m` (~2.5ms) in every shell on a new tty, to catch an SSH login whose `SSH_*` vars were lost (su on a remote host). `plugins.zsh` presets `P9K_SSH=0` when no `SSH_*` var is set.
- **p10k console capture**: instant prompt sends stdout to a file until the prompt is first expanded, after every precmd hook, and a non-empty file costs p10k a `cat` fork (~3ms). omz's title and OSC 7 hooks were the only writers, so `plugins.zsh` takes them out of `precmd_functions` and adds them back from the zsh-defer queue, which also runs them once at startup instead of twice.
- **atuin session**: atuin's init forks `atuin uuid` (~5.5ms) in every new shell, since its `ATUIN_SHLVL` check never matches a new `SHLVL`. `evals.zsh` mints the same simple-format UUIDv7 in zsh first, so that check passes.
- **atuin search index**: atuin's init starts `atuin __internal prepare-search-index` in every shell (~1.5ms before the prompt, plus a background process), a no-op unless `search_mode = daemon-fuzzy`. `evals.zsh` greps that line out of the cached script, so moving to that search mode means dropping the filter.
- **ssh-agent**: the plugin runs `ssh-add -l` and `ssh-keygen -lf` in every shell (~8ms of the deferred queue; the agent's key comments never match a file path, so the fingerprint check always runs). `plugins.zsh` sets its `lazy` zstyle when an inherited `SSH_AGENT_PID` is alive, since the shell that found the agent loaded the identity. After a manual `ssh-add -D`, a top-level shell or the first use (`AddKeysToAgent`) adds it back. It names its env file after `SHORT_HOST`, which `plugins.zsh` exports so child shells skip the `scutil` fork.
- **zoxide hook**: zoxide's chpwd hook blocks `cd` on `$(pwd)` plus a synchronous database write (~8ms), so `evals.zsh` redefines `__zoxide_hook` to run in the background. zoxide's atomic rename keeps the database intact; `cd`s within a few ms of each other can lose a score increment.
- **zsh-patina daemon**: `zsh-patina activate` prints the init script and also launches the highlighter daemon (~3.3ms per shell for the fork), and the script it prints only returns while the daemon's socket is missing, so a cached copy alone would leave highlighting dead after a reboot or a crash. `evals.zsh` checks the socket and the pid in `$TMPDIR/zsh-patina/daemon.lock` first, runs `zsh-patina start` (silent, idempotent) only when the daemon is down, then evalcaches `activate` like the other tools.
- **/etc/zshrc**: skipped with `global_rcs` off in `.zshenv`. It forks `locale` (~4ms) in every interactive shell, and omz and p10k override the rest of it (history, key bindings, prompt) except `combining_chars` and `disable log`, which `options.zsh` keeps.
- **/etc/zprofile**: `.zshenv` sources it itself in a top-level login shell, ahead of `user_path`, so path_helper never gets to move the system dirs in front. Login shells below `SHLVL` 1 (tmux panes) inherit its PATH and LANG and would only fork path_helper again (~2ms).
- **zsh-autosuggestions**: `ZSH_AUTOSUGGEST_MANUAL_REBIND` wraps the widgets once, when the plugin starts, instead of re-binding ~210 of them every precmd. `.zplugins` must therefore load it after every other widget-defining plugin (fzf-tab), since it starts from the precmd hooks zsh-defer runs right after it loads.
  - Those hook runs and the repaint are kept for this last plugin only: the `defer-options` zstyles turn them off for ssh-agent and fzf-tab (~2ms). Antidote bakes the options into the bundle, so changing them needs a `touch ~/.zplugins`.
  - atuin's init prepends its own strategy, which spawns `atuin search` per fetch (~10-25ms). `evals.zsh` sets `(history atuin completion)` after it, so zsh's history answers in-process and atuin covers what the history file has dropped.
- **zcompile**: only the plugins (`zstyle ':antidote:bundle:*' zcompile 'yes'`), the evalcache scripts and the completion dump are compiled. `.zshrc` would gain ~15µs and the config modules ~0.2ms, which doesn't pay for the staleness and concurrency handling a `.zwc` needs.
- **Autoload**: Functions in `.config/zsh/functions/` are registered via `autoload -Uz` and only loaded on first call.
- **OSC 7 cwd reporting**: omz's `omz_termsupport_cwd` forks two subshells per prompt to URL-encode `$HOST` and `$PWD`; a redefinition at the end of `plugins.zsh` encodes both in-process when `$PWD` changes and re-emits the cached sequence each prompt (still every prompt, so the terminal's recorded cwd survives `reset` and tmux reattach). It calls p10k's private `_p9k_url_escape`, which also encodes the `?` that omz leaves raw and a URI parser would cut the path at. It hardcodes omz's format and leaves out omz's Konsole branch.
- **compinit**: `plugins.zsh` runs it ahead of the bundle, since omz's `lib/directories.zsh` calls `compdef` unguarded and the tools' init scripts skip theirs without it. So `fpath` has to be complete by then, which is why `brew shellenv` runs there too. `$ZSH_COMPDUMP` holds only the `command => function` map.
  - `-C` skips compinit's own check, a glob of every `_*` file on `fpath` (~5ms). Instead, `plugins.zsh` deletes the dump when any `fpath` dir is newer than it, and the dump's name carries zsh's version. That costs a ~155ms rebuild in the next shell after `yay`, a brew change to `site-functions`, or an edit in `compdefs/` or `functions/`.
  - A plugin's `fpath+=` in the bundle comes after compinit, so a plugin that ships `_*` files needs its dir on `fpath` earlier. None does today.

## Common Commands

```bash
profile               # Profile zsh startup time (zsh -i -c exit, so without the first prompt's precmd or the deferred plugins)
sync-dots zsh         # Deploy zsh config via stow
sync-forks [-j <n>]   # Merge upstream into every hareki fork's default branch, n forks at a time (default 10), then fast-forward each fork's clone in $REPOS_DIR from origin, or start a conflicting merge in the clone (unless --no-local-merge)
yay                   # Update all package managers (brew, antidote, mise, tpm)
build <target>        # Build a local tool from source into ~/.local/opt/bin (atuin, eza, fzf, lazygit, television, worktrunk; tmux goes to /usr/local)
cts                   # Toggle git skip-worktree on claude-code settings.json (model/effort churn)
ff                    # fastfetch with buffered output
mux <project>         # tmuxinator start, from a throwaway session outside tmux so the layouts are built at the terminal's size
```

## Conventions

- New utility functions go in `.config/zsh/functions/` as standalone files (one function per file, filename = function name, no `.zsh` extension, since `autoload` looks the file up by function name). They are autoloaded automatically.
- All custom completions go in `.config/zsh/compdefs/`, one file per command named `_<command>` (e.g. `_build`, `_tv`) whose first line is `#compdef <command>`. This covers both the autoloaded functions above and external commands. The file body _is_ the completion function, so it needs no wrapper and no trailing `compdef` call. The directory is on `fpath`, so compinit registers the tag and autoloads the body on first use. A command family may share one file, and a vendor script meant for `.zshrc` gets a compdef that sources it on first use (both: `_gcloud`).
- **Stale completion dump.** `$ZSH_COMPDUMP` caches only the `command => function` mapping, and `plugins.zsh` rebuilds it when an `fpath` dir's mtime passes it. So:
  - Picked up on the next shell, no action needed: editing a compdef's body (bodies are autoloaded from `fpath` at completion time, never cached), and adding, deleting or renaming a compdef, here or in a third-party `fpath` dir.
  - Goes **stale**, since the dir's mtime doesn't change: rewriting a `#compdef` line in place without creating or renaming a file in the dir (an editor's temp file or atomic save does bump it).
  - Fix: `rm $ZSH_COMPDUMP $ZSH_COMPDUMP.zwc`, then start a new shell.
- Aliases go in `.config/zsh/aliases.zsh`. Commands run through `$SHELL -c` (television's cables) spell out their flags, since only `.zshenv` reaches those shells and it stays free of aliases.
- Interactive env vars / history overrides / fzf options go in `.config/zsh/options.zsh`. Tool init (`zoxide`, `atuin`, `wt`, `zsh-patina`) goes in `.config/zsh/evals.zsh`.
- Plugin configuration (zstyles, env vars) goes in `.config/zsh/plugins.zsh`, before the bundle is sourced. Overrides of what the bundle itself sets go after it: redefinitions of a plugin function (e.g. `omz_termsupport_cwd`, which the bundle would overwrite) and zstyles omz sets under a more specific pattern (e.g. its `':completion:*:*:*:*:*' menu select`, which outranks any `':completion:*'` style).
- Color theme is **Catppuccin Mocha** throughout (fzf, zsh-patina syntax highlighting, eza, etc.).
- Paths assume Homebrew at `/opt/homebrew/`.
