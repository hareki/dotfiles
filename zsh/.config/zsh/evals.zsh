_evalcache zoxide init zsh
# Its hook would block every `cd` on `$(pwd)` plus zoxide's database write (~8ms)
__zoxide_hook() { command zoxide add -- "$PWD" &! }

# Mint atuin's simple-format UUIDv7 here, sparing its init an `atuin uuid` fork (~5.5ms)
# per shell; atuin reads the session's start time back out of the timestamp
if [[ -z $ATUIN_SESSION || $ATUIN_SHLVL != $SHLVL ]]; then
  zmodload zsh/datetime
  printf -v ATUIN_SESSION '%012x7%03x%x%03x%04x%04x%04x' \
    $(( epochtime[1] * 1000 + epochtime[2] / 1000000 )) \
    $(( RANDOM & 0xfff )) $(( 8 | RANDOM & 3 )) $(( RANDOM & 0xfff )) $RANDOM $RANDOM $RANDOM
  export ATUIN_SESSION ATUIN_SHLVL=$SHLVL
fi
# Drop the init's per-shell `prepare-search-index`, a no-op unless search_mode = daemon-fuzzy
_evalcache sh -c 'atuin init zsh --disable-up-arrow | grep -v prepare-search-index'
# The init prepends its strategy, a process per fetch (~10-25ms); zsh's history answers
# in-process, and atuin still covers what the history file has dropped
ZSH_AUTOSUGGEST_STRATEGY=(history atuin completion)

_evalcache wt config shell init zsh

# A cached `activate` can't start the daemon, so revive it here after a reboot or crash
() {
  local d=${TMPDIR:-/tmp}/zsh-patina
  [[ -S $d/daemon.sock ]] && { kill -0 "$(<$d/daemon.lock)" } 2>/dev/null || zsh-patina start
}
_evalcache zsh-patina activate
