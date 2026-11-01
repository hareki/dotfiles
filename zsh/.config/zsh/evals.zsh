# mroth/evalcache minus the md5 fork: keyed by args alone, so function body edits go stale
_evalcache() {
  local cache="$ZSH_CACHE_DIR/init-${${(j:-:)@}//[^A-Za-z0-9_.-]/_}.sh"
  if [[ ! -s $cache ]]; then
    # Per-shell temps are moved in whole, so shells started together (tmuxinator) can't
    # clobber or half-read them; `rm init-*` skips the dot, and two-arg zcompile survives mv
    local tmp="${cache:h}/.${cache:t}.$$"
    "$@" >"$tmp" || { rm -f "$tmp"; print -u2 "_evalcache: '$*' failed"; return 1 }
    mv -f "$tmp" "$cache"
    zcompile "$tmp.zwc" "$cache" && mv -f "$tmp.zwc" "$cache.zwc"
  fi
  source "$cache"
}

# `yay` and `build` call this, since updated tools may emit different init output. The
# _git digest from completion.zsh goes too, as nothing else notices a new _git or zsh
_evalcache_clear() {
  rm -f "$ZSH_CACHE_DIR"/init-*(N) "$ZSH_CACHE_DIR"/_git.zwc
}

# zoxide's own hook would block every `cd` on `$(pwd)` plus its database write (~8ms)
_evalcache zoxide init zsh --hook none
_zoxide_add() { command zoxide add -- "$PWD" &! }
add-zsh-hook chpwd _zoxide_add

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
{ kill -0 "$(<${TMPDIR:-/tmp}/zsh-patina/daemon.lock)" } 2>/dev/null || zsh-patina start
_evalcache zsh-patina activate
