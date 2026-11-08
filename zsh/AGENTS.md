# AGENTS.md

## Architecture

This is a zsh dotfiles configuration targeting macOS with Homebrew. `sync-dots zsh` deploys these files to `$HOME` with GNU stow. Root-level package metadata (AGENTS.md, CLAUDE.md, GLOSSARY.md, README.md, assets, tests) is excluded by root-anchored patterns in `stow/.stow-global-ignore`. Terms: [GLOSSARY.md](./GLOSSARY.md).

### Sourcing Order

```
.zshenv  (all shells)
  => XDG_CONFIG_HOME, EDITOR, VISUAL, EZA_CONFIG_DIR, CLOUDSDK_PYTHON, API keys (from macOS keychain; skipped when inherited from a parent shell)
  => a top-level login shell (SHLVL 1) sources /etc/zprofile (path_helper, LANG)
  => unsetopt global_rcs (zsh itself reads no other /etc rc)
  => PATH: typeset -U, then the user dirs prepended (~/.local/bin/shims, ~/.local/opt/bin, mise shims, Homebrew, then the gcloud SDK bin for `gcloud components` binaries)

.zshrc  (interactive shells)
  => zmodload zprof if $ZSH_DEBUGRC
  => ~/.p10k.zsh (prompt config)
  => config modules in order:
     plugins:
       the plugin options
       the brew shellenv lines anything reads
       the Antidote bundle, then omz's update check
       overrides of what the bundle set
     aliases, vi-mode, keymaps, options, completion, evals, tty-guard
  => autoload functions from .config/zsh/functions/
```

The sourcing order of config modules matters: later files depend on earlier ones. keymaps' plain `bindkey` calls and the `^X` keys compinit binds in the main keymap only reach viins because vi-mode's `bindkey -v` has replaced omz's `bindkey -e` by then, and the tools in evals call the `compdef` that compinit defines.

- `options.zsh` holds interactive-only settings (`REPOS_DIR`/`STOW_REPO`, `PROMPT_EOL_MARK`, `combining_chars` and `disable log` from the skipped `/etc/zshrc`, what's kept of skipped omz libs) and the Catppuccin `FZF_DEFAULT_OPTS` / `_ZO_FZF_OPTS`. History settings come from omz's `lib/history.zsh`.
- `completion.zsh` puts `.config/zsh/compdefs/` on `fpath`, runs compinit and turns zsh's menu off for fzf-tab.
- `evals.zsh` defines `_evalcache` and runs tool init through it: zoxide (with its own background hook), atuin (after minting its session ID, minus one init line, then resets the autosuggest strategy, see Performance Patterns), `wt` (worktrunk) and zsh-patina (syntax highlighter, after the daemon check described there).
- `tty-guard.zsh` is a `sched`-driven self-heal for the tty being put back into cooked mode while zle is reading the line (Node.js restores its startup termios on exit, even from a background process group): one `stty -g` per idle 2s tick, an empty `zle -M` to force `zsetterm` when icanon/echo are set.

### Plugin Management

Plugins are declared in `.zplugins` and managed by Antidote. Antidote statically generates a bundled file (`.zplugins.bundled.zsh`) that is only regenerated when `.zplugins` changes. fzf-tab and zsh-autosuggestions load through `kind:defer`; the omz libs and p10k load eagerly.

`.zplugins` lists only the omz lib files this config uses instead of all of `lib` (~5ms per shell), and omz's own loader isn't used either: `plugins.zsh` sets the `$ZSH` and `$ZSH_CACHE_DIR` that the libs and the updater read and runs `tools/check_for_upgrade.sh` itself, and `completion.zsh` runs compinit. Helpers from the other lib files (`omz`, `clipcopy`, `git_prompt_info`, ...) don't exist here, so add a lib file to the list when something starts to need it.

- `lib/directories.zsh`: `options.zsh` keeps its `auto_cd` and `aliases.zsh` its `l`. The lib's unguarded `compdef` would need compinit ahead of the bundle.
- `lib/theme-and-appearance.zsh`: `options.zsh` keeps its `LSCOLORS` and `aliases.zsh` its `ls -G`. p10k sets `prompt_subst` itself, and the `LS_COLORS` it exported would override eza's theme.
- `lib/vcs_info.zsh`: its only job is quoting `%` in a branch name for p10k's `vcs_info` fallback, which runs only while gitstatusd is down.
- `lib/grep.zsh`: `aliases.zsh` keeps its `grep` alias. The lib re-probes flags macOS's grep always has, daily, to write that same alias to a cache file, and its `egrep` and `fgrep` aliases had no use.

### Performance Patterns

- **evalcache**: A small local `_evalcache` in `evals.zsh` wraps expensive `eval "$(command)"` calls (zoxide, atuin, wt, zsh-patina); output cached and zcompiled as `init-*` in `$ZSH_CACHE_DIR`, invalidated by `_evalcache_clear` (`yay` and `build` call it after updating tools).
  - Its zprof time is the cached scripts' own code: the wrapper adds ~10µs over a bare `source`, which already loads the `.zwc`. Sourcing the `.zwc` directly fails (zsh parses it as text).
- **brew shellenv**: `plugins.zsh` holds only the lines of `brew shellenv zsh` that something reads: `HOMEBREW_PREFIX` (zig's native search paths have no fallback), `fpath`'s `site-functions` entry, and `MANPATH`'s leading empty entry, which stands for man's default dirs. `.zshenv` has already set the `PATH` dirs. Left out: `HOMEBREW_CELLAR` and `HOMEBREW_REPOSITORY` (brew sets its own), `INFOPATH` (no `info` is installed, and it gained a copy per nested shell) and `export FPATH`, which only carried a parent's stale entries into child shells that build their own `fpath` anyway. Lines brew adds later don't arrive on their own, so `brew shellenv zsh` is the reference when one turns out to be missing.
- **mise**: not activated at runtime; it runs purely via shims prepended to `PATH` in `.zshenv`. A shim costs ~25ms per call (~65ms for a tool installed in mise but inactive in the current directory, e.g. claudecode.nvim's pinned fzf/neovim outside that project), so hot paths bypass it:
  - `build` installs into `~/.local/opt/bin` (`CARGO_INSTALL_ROOT`/`GOBIN`, tmux's `--prefix`), which `.zshenv` puts ahead of the mise shims. Left in the toolchains' own dirs (`~/.cargo/bin`, mise's versioned go bin), atuin would pay the shim cost at every startup and before every command.
  - fzf is a `build` target too (the hareki/fzf fork, which drops the blank column inside borders and adds the `--max-width` in fzf-tab's `fzf-flags`, an option a stock fzf rejects), so fzf-tab's plain `fzf` lookup lands there instead of the shim for claudecode.nvim's pinned fzf.
  - `[settings.shims] exclude` in mise's config drops the shims of tools that only project configs pin (jq, stylua), so a bare `jq` or `stylua` reaches Homebrew's binary directly. A new entry takes effect at the next `mise reshim`, which every mise install or upgrade runs.
  - nvim stays shimmed, though only claudecode.nvim pins neovim: a shim that falls through to Homebrew's nvim still puts every active tool's install dir ahead of the shims on `PATH`, so the language servers, formatters and `node` an editing session starts skip a shim (~23ms each). Short-lived nvims name `/opt/homebrew/bin/nvim` instead: tsave's and lazygit's RPC clients, and Claude Code's editor (`bin/.local/bin/shims/nvim-claude`).
- **gcloud python**: `CLOUDSDK_PYTHON` points gcloud/bq/gsutil at an on-request python@3.13 (so `brew autoremove` leaves it alone). Unset, the SDK's wrapper first runs a python just to vet it (3.9-3.14, which rules out mise's): ~60ms => ~45ms per TAB. Any accepted python works, and a stale path fails the `-x` check and falls back to that probe.
- **gcloud completion**: the SDK's bash-style `completion.zsh.inc`, which its installer sources from `.zshrc` (~3ms), is sourced by `compdefs/_gcloud` on the first TAB instead. Its `complete` calls re-register gcloud/gsutil/bq with `_bash_complete`, so later TABs skip `_gcloud`. `_bash_complete` runs the SDK's functions in a `$(compgen ...)` subshell, so bq's `bq_COMMANDS` cache never survives and every `bq` TAB re-runs `bq help` (~0.4s). Homebrew's `site-functions/_google_cloud_sdk` lacks a `#compdef` line, so compinit ignores it.
- **p10k SSH probe**: p10k forks `who -m` (~2.5ms) in every shell on a new tty, to catch an SSH login whose `SSH_*` vars were lost (su on a remote host). `plugins.zsh` presets `P9K_SSH=0` when no `SSH_*` var is set.
- **p10k dumps**: with the instant prompt off, `_p9k_should_dump` still fires at each shell's first prompt and in each dir new to that shell, because the check that keeps p10k's record of dumped dirs reads a variable only the instant prompt script sets. Each dump rewrites the state and an instant prompt nothing reads (~5ms, blocking zle). `plugins.zsh` overrides that private function to dump only when a cache changed; cold starts, config changes and dirs no shell has seen still dump. The override applies only while `POWERLEVEL9K_INSTANT_PROMPT` is off (`p10k/.p10k.zsh`), so turning the instant prompt back on brings p10k's own check back. Drop it if p10k's cache goes stale.
- **omz updater**: `tools/check_for_upgrade.sh` runs in `auto` mode, in the first shell past the 13-day mark. `verbose silent` is what the instant prompt used to force; without it an update prints a banner and the changelog above the first prompt. With no instant prompt to paint first, that shell stays blank while the update runs (~1.2s).
- **atuin session**: atuin's init forks `atuin uuid` (~5.5ms) in every new shell, since its `ATUIN_SHLVL` check never matches a new `SHLVL`. `evals.zsh` mints the same simple-format UUIDv7 in zsh first, so that check passes.
- **atuin search index**: atuin's init starts `atuin __internal prepare-search-index` in every shell (~1.5ms before the prompt, plus a background process), a no-op unless `search_mode = daemon-fuzzy`. `evals.zsh` greps that line out of the cached script, so moving to that search mode means dropping the filter.
- **atuin AI**: `--disable-ai` keeps `?` a plain key. Without it, `?` on an empty line starts `atuin ai inline`, a feature nothing here uses, and the init carries 58 more lines.
- **SSH keys**: no shell-managed agent. `ssh/.ssh/config` names the key for `github.com` and both aliases, and neither key has a passphrase, so `ssh` reads it directly from any process, GUI apps included. `AddKeysToAgent` hands it to launchd's agent on first use. omz's ssh-agent plugin cost a daemon, a state file, `ssh-add -l` plus `ssh-keygen -lf` in the deferred queue (~8ms) and a `scutil` fork (~5.5ms) at top level.
- **zoxide hook**: zoxide's chpwd hook blocks `cd` on `$(pwd)` plus a synchronous database write (~8ms), so `evals.zsh` turns it off with `--hook none` and adds one that runs in the background. zoxide's atomic rename keeps the database intact; `cd`s within a few ms of each other can lose a score increment.
- **zsh-patina daemon**: `zsh-patina activate` prints the init script and also launches the highlighter daemon (~3.3ms per shell for the fork), and the script it prints only returns while the daemon's socket is missing, so a cached copy alone would leave highlighting dead after a reboot or a crash. `evals.zsh` checks the pid in `$TMPDIR/zsh-patina/daemon.lock` first, runs `zsh-patina start` (silent, idempotent) only when the daemon is down, then evalcaches `activate` like the other tools. A check of the socket adds nothing: `start` does nothing while that pid lives, and a reboot empties `$TMPDIR`, so a stale lock can't outlive one. The cached script holds the socket path of the shell that built it, so a cache rebuilt under another `TMPDIR` (a test harness, a sandboxed agent shell) leaves highlighting off until the next `_evalcache_clear`.
- **/etc/zshrc**: skipped with `global_rcs` off in `.zshenv`. It forks `locale` (~4ms) in every interactive shell, and omz and p10k override the rest of it (history, key bindings, prompt) except `combining_chars` and `disable log`, which `options.zsh` keeps.
- **/etc/zprofile**: `.zshenv` sources it itself in a top-level login shell, ahead of the user dirs, so path_helper never gets to move the system dirs in front. Login shells below `SHLVL` 1 (tmux panes) inherit its PATH and LANG and would only fork path_helper again (~2ms).
- **zsh-autosuggestions**: `ZSH_AUTOSUGGEST_MANUAL_REBIND` wraps the widgets once, when the plugin starts, instead of re-binding ~210 of them every precmd. `plugins.zsh` queues the plugin's private `_zsh_autosuggest_start` behind every deferred plugin, so the wrap covers fzf-tab's widgets.
  - The `defer-options` zstyle turns off zsh-defer's precmd re-run and repaint after each deferred plugin (~3ms). Antidote bakes the options into the bundle, so changing them needs a `touch ~/.zplugins`.
  - `ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=100` skips the ~14% of fetches past 100 characters, which replayed history shows finding a suggestion 3 times per 3,000 commands. A suggestion already showing keeps tracking past the limit.
  - atuin's init prepends its own strategy, which spawns `atuin search` per fetch (~10-25ms). `evals.zsh` sets `(history atuin completion)` after it, so zsh's history answers in-process and atuin covers what the history file has dropped.
- **zcompile**: only the plugins (`zstyle ':antidote:bundle:*' zcompile 'yes'`), the evalcache scripts, the completion dump and `_git` are compiled. `.zshrc` would gain ~15µs and the config modules ~0.2ms, which doesn't pay for the staleness and concurrency handling a `.zwc` needs.
- **Autoload**: Functions in `.config/zsh/functions/` are registered via `autoload -Uz` by absolute path and only loaded on first call. The dir stays off `fpath`, where an edit there would cost a dump rebuild that can't change anything (it holds no `_*` files).
- **OSC 7 cwd reporting**: `plugins.zsh` removes omz's `omz_termsupport_cwd` hook, which forks twice per prompt for a sequence nothing here reads. Ghostty's shell integration reports the cwd itself at top level. tmux stores it in `#{pane_path}`, which no config or plugin uses (`pane_current_path` comes from the OS), and forwards it only with `set-titles on` plus the `osc7` terminal feature. nvim's `:terminal` needs a `TermRequest` handler, and blink.cmp's reads only OSC 133. Restore the hook when one of those starts to read it.
- **Paste**: `lib/misc.zsh` binds `bracketed-paste-magic`, which replays every pasted character through the widget chain: 326ms per 2KB, and most 8KB pastes stalled until the next key. `plugins.zsh` rebinds zsh's `bracketed-paste-url-magic` (3.8ms, 12ms, no stalls), which quotes a paste that starts with a URL, so an unquoted URL inside a pasted command stays literal. Typed URLs still go through `url-quote-magic`. The widget's `zle -f yank` would show the paste in standout, hence `paste:none` in `zle_highlight`.
- **compinit**: `completion.zsh` runs it after the bundle, so every plugin's `fpath+=` counts, and ahead of the tools' init scripts, which skip their `compdef` without it.
  - `-C` skips compinit's own check, a glob of every `_*` file on `fpath` (~5ms). Instead, `completion.zsh` deletes the dump when any `fpath` dir is newer than it, and the dump's name carries zsh's version. That costs a ~155ms rebuild in the next shell after `yay`, a brew change to `site-functions`, or an edit in `compdefs/`.
- **_git**: the system's `_git` is 388KB of zsh, so a shell's first `git <TAB>` spends ~95ms parsing it, and so does each async suggestion that reaches the `completion` strategy on a `git` line until the main shell has loaded it (~115ms => ~25ms per fetch). `completion.zsh` compiles it to `$ZSH_CACHE_DIR/_git.zwc`, which `_evalcache_clear` drops, and autoloads it by absolute path.
  - That has to come ahead of compinit: a function already marked for autoload ignores the path, silently. `-d` falls back to `fpath` when a zsh update leaves a digest of the wrong version, which would otherwise be an error.
  - No other completion is worth it: `_brew` parses in ~13ms, `_tmux` in ~6ms, the rest in less.

## Common Commands

```bash
profile               # Profile zsh startup time (zsh -i -c exit, so without the first prompt's precmd or the deferred plugins)
sync-dots zsh         # Deploy zsh config via stow
sync-forks [-j <n>]   # Rebase every hareki fork's default branch onto upstream's, n forks at a time (default 10), in its clone in $REPOS_DIR (cloned if missing), then force-push it and bring the clone's branch along, or start a conflicting rebase in the clone (unless --no-local-rebase)
yay                   # Update all package managers (brew, antidote, mise, global agent skills, tpm)
build <target>        # Build a local tool from source into ~/.local/opt/bin (atuin, eza, fzf, lazygit, television, tmux, worktrunk)
cts                   # Toggle git skip-worktree on claude-code settings.json (model/effort churn)
ff                    # fastfetch with buffered output
mux <project>         # tmuxinator start, from a throwaway session outside tmux so the layouts are built at the terminal's size
tsave [-c|--continue] # tmux-resurrect snapshot, then quit every pane nvim cleanly and kill tmux (unless --continue); refuses while any nvim holds unsaved work
trestore [<id>]       # Restore a snapshot (default: `last`) into a fresh tmux server; --list shows ids newest first, --force restores into a busy server
```

## Tests

- **Test**: `tests/run.zsh [words]` runs the test files in `tests/` (all, or those whose name contains a word), each in its own `zsh -f` started from `env -i`, with a private scratch dir under `/tmp/zt.*` as its HOME and TMPDIR. A test file asserts through `tests/lib/helpers.zsh` and drives a command through its own interface, with stand-ins for what it reaches
- **A/B**: `tests/ab.zsh [rev]` boots `rev` (default `HEAD`) and the working tree, each in a scratch HOME as a top-level login shell and as a login shell started from it, and diffs what each defines once the deferred plugins have loaded: options, aliases, functions (by body length), widgets, every keymap, zstyles, the completion table, hooks, exported variables, paths, modules, parameter types and config values (`tests/lib/dump.zsh`). Two boots of one tree dump identically, so every diff row is a change to account for, a module moved in the `.zshrc` loop included; `ZT_AB_KEEP=<dir>` keeps both dumps
- **`sync-forks`**: 21 scenarios on bare-repo stand-ins for GitHub (`url.insteadOf` rewrites, `GIT_ALLOW_PROTOCOL=file`, a `gh` function), every fork synced twice so the second run proves a sync settles: each fork's report line, the end sections and exit status, the refs on "GitHub" and in the clone, and the fetches each fork costs
- **`snapshots`**: the snapshot store (`tmux/.config/tmux/scripts/resurrect-snapshots.zsh`), `tsave` and `trestore`, against a private tmux server that loads this tree's tmux config and the installed TPM plugins: the listing, `select`, saves, expiry, `tsave` up to its kill, and a restore from scratch
- **`overrides`** (worth a run after `yay`): a cold and a warm boot, with logging stand-ins for `who`, `atuin` and `zsh-patina`, check that each line leaning on a plugin's private name still stops what it exists to stop: p10k's `who` fork and its repeat dumps, atuin's `uuid` fork and search-index start, `zsh-patina start` while the daemon runs, omz's cwd hook, fzf-tab's Tab widget left unwrapped by autosuggestions. A test's own questions for a booted shell go in a file `ZT_PROBE` names (`zt_boot` in `tests/lib/env.zsh`)
- Scratch shells follow `tests/lib/env.zsh`, whose rules each cost a real incident: dummy API keys and never an xtrace or environment dump, `env -i` for every boot, a scratch HOME laid out like stow, a short private TMPDIR, a current omz update stamp, and mise's real dirs with installs off. Never run `sync-forks`, `tsave` or `yay` for real to test them

## Conventions

- New utility functions go in `.config/zsh/functions/` as standalone files (one function per file, filename = function name, no `.zsh` extension, since `autoload` names the function after the file).
- All custom completions go in `.config/zsh/compdefs/`, one file per command named `_<command>` (e.g. `_build`, `_tv`) whose first line is `#compdef <command>`. This covers both the autoloaded functions above and external commands. The file body _is_ the completion function, so it needs no wrapper and no trailing `compdef` call. The directory is on `fpath`, so compinit registers the tag and autoloads the body on first use. A command family may share one file, and a vendor script meant for `.zshrc` gets a compdef that sources it on first use (both: `_gcloud`).
- **Stale completion dump.** `$ZSH_COMPDUMP` caches only the `command => function` mapping, and `completion.zsh` rebuilds it when an `fpath` dir's mtime passes it. So:
  - Picked up on the next shell, no action needed: editing a compdef's body (bodies are autoloaded from `fpath` at completion time, never cached), and adding, deleting or renaming a compdef, here or in a third-party `fpath` dir.
  - Goes **stale**, since the dir's mtime doesn't change: rewriting a `#compdef` line in place without creating or renaming a file in the dir (an editor's temp file or atomic save does bump it).
  - Fix: `rm $ZSH_COMPDUMP`, then start a new shell.
- Aliases go in `.config/zsh/aliases.zsh`. Commands run through `$SHELL -c` (television's cables) spell out their flags, since only `.zshenv` reaches those shells and it stays free of aliases.
- Interactive env vars / history overrides / fzf options go in `.config/zsh/options.zsh`. Tool init (`zoxide`, `atuin`, `wt`, `zsh-patina`) goes in `.config/zsh/evals.zsh`.
- Plugin configuration (zstyles, env vars) goes in `.config/zsh/plugins.zsh`, before the bundle is sourced. Overrides of what the bundle itself sets go after it: widget and hook changes (e.g. the `bracketed-paste` rebind, which `lib/misc.zsh` would overwrite) and zstyles omz sets under a more specific pattern (e.g. its `':completion:*:*:*:*:*' menu select`, which outranks any `':completion:*'` style and is reset in `completion.zsh`).
- Color theme is Catppuccin Mocha throughout (fzf, zsh-patina syntax highlighting, eza, etc.).
- Paths assume Homebrew at `/opt/homebrew/`.
