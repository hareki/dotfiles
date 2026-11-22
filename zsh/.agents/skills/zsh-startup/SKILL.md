---
name: zsh-startup
description: What every zsh shell runs at startup, covering `.zshenv`, `.zshrc`, the config modules, Antidote plugins and omz libs, tool init and the overrides that keep startup fast. Use when adding or changing a setting, a plugin, an omz lib or a tool's init, editing an override, or measuring startup time.
---

# zsh startup

1. Read [`docs/conventions/startup.md`](../../../docs/conventions/startup.md).
2. Before changing or removing a line in `plugins.zsh`, `evals.zsh`, `completion.zsh` or `.zshenv`, read its entry in [`docs/startup-overrides.md`](../../../docs/startup-overrides.md).

## Check

1. Measure with `profile`, minding what it leaves out (`docs/conventions/startup.md`, Measuring).
2. Run `tests/ab.zsh` and account for every diff row (the `zsh-testing` skill).
3. Run `tests/run.zsh overrides` after touching an override or updating the plugins it leans on.
