_evalcache zoxide init zsh
_evalcache atuin init zsh --disable-up-arrow
_evalcache wt config shell init zsh

# _evalcache doesn't work reliably for this, only works when cache is empty
eval "$(zsh-patina activate)"
