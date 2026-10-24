_evalcache zoxide init zsh
# Mint atuin's simple-format UUIDv7 here, sparing its init an `atuin uuid` fork (~5.5ms)
# per shell; atuin reads the session's start time back out of the timestamp
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
