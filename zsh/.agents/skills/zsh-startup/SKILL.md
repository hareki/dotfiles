---
name: zsh-startup
description: What every zsh shell runs at startup, covering `.zshenv`, `.zshrc`, the config modules, Antidote plugins and omz libs, tool init and the overrides that keep startup fast. Use when adding or changing a setting, a plugin, an omz lib or a tool's init, editing an override, or measuring startup time.
---

# zsh startup

## Sourcing order

`.zshenv` runs in every shell, including the `$SHELL -c` shells television's cables start. `.zshrc` runs in interactive shells only, and sources the config modules in the order its loop names them.

The loop's order is load-bearing. keymaps' plain `bindkey` calls and the `^X` keys compinit binds in the main keymap reach viins only because vi-mode's `bindkey -v` has already replaced omz's `bindkey -e`. The tools in evals call the `compdef` that compinit defines. Moving a module means checking what it reads from the ones before it.

## Where a line goes

- **`.zshenv`**: what every shell needs, `PATH` included.
- **`options.zsh`**: interactive env vars and fzf options. The history settings all come from omz's `lib/history.zsh`.
- **`evals.zsh`**: tool init (`zoxide`, `atuin`, `wt`, `zsh-patina`), through `_evalcache` when the init is an `eval "$(command)"`.
- **`plugins.zsh`**, before the bundle is sourced: plugin configuration (zstyles, env vars).
- **`plugins.zsh`**, after the bundle: overrides of what the bundle itself sets, such as widget and hook changes (the `bracketed-paste` rebind, which `lib/misc.zsh` would overwrite).
- **`completion.zsh`**: zstyles omz sets under a more specific pattern, such as its `':completion:*:*:*:*:*' menu select`, which outranks any `':completion:*'` style.
- **Theme**: Catppuccin Mocha throughout (fzf, zsh-patina, eza).

## Plugins

`.zplugins` lists the plugins; Antidote regenerates `~/.zplugins.bundled.zsh` only when `.zplugins` is newer. Zstyles that Antidote bakes into the bundle (`defer-options`, `zcompile`) take effect only after a `touch ~/.zplugins`.

omz's own loader isn't used, and `.zplugins` names only the lib files this config uses. Helpers from the other libs (`omz`, `clipcopy`, `git_prompt_info`, ...) don't exist here: add the lib to `.zplugins` when something starts to need one. These four are left out on purpose:

- `lib/directories.zsh`: `options.zsh` keeps its `auto_cd` and `aliases.zsh` its `l`. The lib's unguarded `compdef` would need compinit ahead of the bundle.
- `lib/theme-and-appearance.zsh`: `options.zsh` keeps its `LSCOLORS` and `aliases.zsh` its `ls -G`. p10k sets `prompt_subst` itself, and the `LS_COLORS` it exported would override eza's theme.
- `lib/vcs_info.zsh`: its only job is quoting `%` in the branch and the other fields of p10k's `vcs_info` fallback, which runs only while gitstatusd is down.
- `lib/grep.zsh`: `aliases.zsh` keeps its `grep` alias. The lib re-probes flags macOS's grep always has, daily, to write that same alias to a cache file, and its `egrep` and `fgrep` aliases had no use.

## Overrides

Most lines in `plugins.zsh`, `evals.zsh`, `completion.zsh` and `.zshenv` spare every shell some work, and several lean on a plugin's private names. [patterns.md](patterns.md) holds the reason and the measured cost behind each one. Read the entry for every such line before changing or removing it.

## Check

1. Measure with `profile` (`zsh -i -c exit`, ~25ms). It skips the first prompt's precmd and the deferred plugins, so the first usable prompt (~45ms) costs more than it shows.
2. Run `tests/ab.zsh` and account for every diff row (the `zsh-testing` skill).
3. Run `tests/run.zsh overrides` after touching an override or updating the plugins it leans on.
