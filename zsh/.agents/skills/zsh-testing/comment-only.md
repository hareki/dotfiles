# Proving a comment-only change

zsh's `functions` re-emits a parsed body without its comments, with strings kept byte-exact, so zsh itself proves that a change touched only comments. Defining the function never runs the file, so `.zshrc` and `.zshenv` are safe to check, and `.zplugins` parses as plain commands.

From the package root, for each changed file `$f`:

```zsh
canon() { zsh -f -c 'eval "__f() {
$1
}" && functions __f' zsh "$1" }
[[ $(canon "$(git show HEAD:./$f)") == $(canon "$(<$f)") ]] && print "$f: comments only"
```

The canonical form also evens out indentation and whitespace, and the parser drops `#!` and `#compdef` lines. So pair it with:

- A text diff of both versions with the `^\s*#` lines dropped and the blank lines kept, so a dropped comment can't hide a layout change.
- A check that every `#!` and `#compdef` line is unchanged.
- `zsh -f -n` on the new file.
- For `.zplugins`, which antidote reads at runtime: `cmp` of the `antidote bundle` output for the old and the new file.

Self-test `canon` once before trusting it: a reworded comment must compare equal, a changed literal unequal.

Inside a worktree session the isolation guard refuses to run zsh scripts in the worktree: take a `git archive HEAD` snapshot first, and run the check from outside after leaving the worktree with `keep`.
