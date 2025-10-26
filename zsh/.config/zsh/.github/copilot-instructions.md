## Project AI Instructions: ZSH Dotfiles

Focused scope: ultra-fast (~110ms) interactive ZSH environment with lazy loading, cached initialization, function autoloading, and ergonomic git/fzf helpers. Provide edits that preserve startup speed and established naming patterns.

### Core Architecture

- Root config fragments: `aliases.zsh`, `plugins.zsh`, `fzf.zsh`, `keymaps.zsh`, `vi-mode.zsh`, `zoxide.zsh`, `compdef.zsh` are sourced (order matters for keymaps/completions). Assume these are loaded from a higher-level `.zshrc` (not in this directory) that sets `__zsh_config_dir`.
- Function autoloading: Every executable file in `functions/` is added to `fpath` and autoloaded (`autoload -Uz ${func:t}`) – do NOT source them manually; define a single top-level function per file whose name matches the filename (hyphens allowed, e.g. `git-bwt`). Avoid side-effects at file parse time—only inside the function body.
- Performance levers: Antidote pre-generates plugin bundle (`antidote bundle <plugins > bundled_file`), `evalcache` wraps expensive env init (`brew shellenv`, `mise activate zsh`, `zoxide init zsh`, `vivid_ls …`), `zcompile` caches `.zshrc`. Any new heavy init must use `_evalcache` or defer inside a function executed on demand.

### Conventions & Patterns

- Naming: Short mnemonic two-letter ergonomics: `fb` = Find Branch, `nvcd` (likely open nvim + cd), `sync-g` / `sync-d` for git/dotfile sync. When adding a function, prefer concise verb-y abbreviation plus optional hyphen for domain (`git-bwt`). Add comment header describing abbreviation expansion.
- FZF usage: Interactive pickers usually pipe candidate list into `fzf-tmux -p --reverse` with width/height percentages. Follow existing style (`-w 60% -h 50%`). Keep queries resilient (filter output: `sed`, `sort -u`, remove decorations). Return silently if selection empty.
- Git helpers: Ensure they gracefully handle detached HEAD, missing branches, or remote tracking (see `fb`). When creating repos (`git-bwt`), echo progress lines and exit early on failure (`|| return 1`). Follow green success message pattern with ANSI code `\033[0;32m`.
- Options: Prefer local scoping (`local var`) and numeric flags (`use_home=0/1`). Use `[[ ]]` tests; quote variable expansions in git/path contexts.

### Safe Change Guidance

- Never introduce unconditional external command invocations in top-level sourced files that add >5–10ms latency; wrap in `_evalcache` or gate by env var.
- When adding plugins: modify the plugins list file (not shown here—likely `plugins.zsh` or a `.plugins` manifest). Ensure Antidote regeneration condition `if [[ ! ${bundled_zsh_plugins} -nt ${zsh_plugins} ]]` still works (touch the source list to trigger rebuild rather than forcing).
- Before adding large functions, consider whether they can be broken into smaller autoloaded helpers to keep interactive shell memory minimal until used.

### Example Patterns

Small interactive selector (model on `fb`):

```
myfn() {
	local choice
	choice=$(some_list_cmd | fzf-tmux -p --reverse -w 60% -h 50%) || return 0
	[[ -z $choice ]] && return 0
	command_using "$choice"
}
```

Robust git action (model on `git-bwt`):

```
fn() {
	[[ -z $1 ]] && echo "Usage: fn <arg>" && return 1
	step command || return 1
	echo -e "\033[0;32mDone\033[0m"
}
```

### External Dependencies (implied)

- Antidote, evalcache, fzf/fzf-tmux, git, zoxide, vivid, mise, powerlevel10k theme, Homebrew.
  If referencing new tools, add guarded checks (`command -v tool >/dev/null || return 1`) rather than failing loudly at startup.

### When Extending

- Keep new function files executable, no shebang required (shebang present is OK but not necessary when autoloaded) – follow existing style though (most have `#!/bin/zsh`).
- Provide terse top-of-file comment describing mnemonic. Avoid long prose.
- Do not echo normal-flow output unless it's interactive progress; silence = success.
- Return 0 on no-op user cancellations (empty fzf selection), non-zero only on real errors.

### PR / Commit Behavioral Hints

- This repo is personal dotfiles: prioritize readability + startup time over abstraction. Avoid adding heavy frameworks.
- Keep instructions self-contained; no need for test harnesses.

### Ask For Clarification

If a requested change risks startup performance or alters autoload mechanics, ask before proceeding.

---

Feedback welcome: Which areas need more detail (plugin list flow, load order, adding keymaps, zcompile triggers)?
