# Zsh config

A personal zsh setup for macOS: a startup tuned for a fast first prompt, the commands built on top of it, and the tests that check both.

## Language

### Startup

**Shape**:
How a shell starts: as a top-level login shell (a terminal's first, at SHLVL 1), or as a login shell started from one.
_Avoid_: mode, kind

**Override**:
A line that presets or replaces a plugin's private variable, function or hook, to spare every shell work the plugin would otherwise do.
_Avoid_: patch, hack, monkey-patch

### Commands

**Target**:
A tool this machine runs from a local build of its source instead of a packaged release.
_Avoid_: package, project, binary

**Checkout**:
The working tree a target is built from.
_Avoid_: source dir, repo

**Stamp**:
The record of which source an installed target was built from.
_Avoid_: marker, cache, lock

**Due**:
Said of a target whose checkout no longer matches its stamp, or that has no stamp, so the next build of every target includes it.
_Avoid_: stale, dirty, outdated

**Fork**:
A repository of this account that follows another's: upstream's default branch with the account's own commits on top, and no merge commits.
_Avoid_: mirror, copy

**Clone**:
A fork's local repository, kept level with the fork as it moves.
_Avoid_: checkout (a target's), working copy

### Tests

**Scratch boot**:
A start of this config's shell in a throwaway home laid out like the deployed one, which reaches none of the machine's live keys, caches or servers.
_Avoid_: sandbox, test shell

**State dump**:
Everything a booted shell defines once its deferred plugins have loaded, written so that two boots compare line by line.
_Avoid_: snapshot, environment dump

**Scratch repos**:
The repositories a command's test builds in its scratch dir to stand for GitHub and the local checkouts, with git cut off from every config and remote outside that dir.
_Avoid_: fixtures, test repos, sandbox
