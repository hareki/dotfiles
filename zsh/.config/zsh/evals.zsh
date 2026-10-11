_evalcache zoxide init zsh
# atuin's init forks `atuin uuid` (~5.5ms) in every new shell, whose SHLVL never
# matches the inherited ATUIN_SHLVL. Mint the same simple-format UUIDv7 here so its
# check passes (atuin reads a session's start time back out of the timestamp)
if [[ -z $ATUIN_SESSION || $ATUIN_SHLVL != $SHLVL ]]; then
  zmodload zsh/datetime
  printf -v ATUIN_SESSION '%012x7%03x%x%03x%04x%04x%04x' \
    $(( epochtime[1] * 1000 + epochtime[2] / 1000000 )) \
    $(( RANDOM & 0xfff )) $(( 8 | RANDOM & 3 )) $(( RANDOM & 0xfff )) $RANDOM $RANDOM $RANDOM
  export ATUIN_SESSION ATUIN_SHLVL=$SHLVL
fi
_evalcache atuin init zsh --disable-up-arrow
_evalcache wt config shell init zsh

# _evalcache doesn't work reliably for this, only works when cache is empty
eval "$(zsh-patina activate)"
