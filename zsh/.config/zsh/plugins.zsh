ZSH_EVALCACHE_DIR="$HOME/.cache/.zsh-evalcache"
ANTIDOTE_HOME="$HOME/.cache/antidote"
# use-omz only skips its `$(antidote path ohmyzsh/ohmyzsh)` subshell (~15ms) when
# $ZSH is already set, which otherwise only holds for shells that inherit it
export ZSH="$ANTIDOTE_HOME/github.com/ohmyzsh/ohmyzsh"

# Cache expensive `eval "$(cmd)"` output; invalidate with _evalcache_clear.
#
# Local replacement for mroth/evalcache without its per-call `echo | md5` fork:
# the args alone are the cache key and filename.
#   - Fine for external binaries with short, distinct args (our only use)
#   - Do NOT reuse for shell functions: body edits go silently stale
#     (upstream hashes `typeset -f` and auto-invalidates)
#   - Do NOT reuse for exotic/long args: sanitization collisions, NAME_MAX overflow
_evalcache() {
  local cache="$ZSH_EVALCACHE_DIR/init-${${(j:-:)@}//[^A-Za-z0-9_.-]/_}.sh"
  if [[ ! -s $cache ]]; then
    mkdir -p "$ZSH_EVALCACHE_DIR"
    # A `tmuxinator start` brings up many shells at once, and on a cold cache
    # every one of them rebuilds: they truncate each other's output, and they
    # collide on zcompile's O_EXCL create of the .zwc ("can't write zwc file").
    # Serialize the rebuild and re-check, so only the first shell does the work.
    # -i: flock's default retry interval is a full second, stalling waiters.
    local lock="$ZSH_EVALCACHE_DIR/.lock" fd
    : >>"$lock"
    zmodload -F zsh/system b:zsystem
    if ! zsystem flock -t 10 -i 0.05 -f fd "$lock"; then
      # Timed out (a rebuild is wedged): run uncached instead of racing it.
      print -u2 "_evalcache: lock timeout, sourcing '$*' uncached"
      source <("$@")
      return
    fi
    {
      if [[ ! -s $cache ]]; then
        # Build both files under dot-prefixed temp names and mv in: a fast-path
        # shell can't read (or SIGBUS on) a half-written file, and
        # _evalcache_clear's `rm init-*` can't delete them mid-build. The two-arg
        # zcompile records the source path, not the output name, so the
        # renamed .zwc stays valid.
        local tmp="${cache:h}/.${cache:t}.$$"
        "$@" >"$tmp" || { rm -f "$tmp"; print -u2 "_evalcache: '$*' failed"; return 1 }
        mv -f "$tmp" "$cache"
        zcompile "$tmp.zwc" "$cache" && mv -f "$tmp.zwc" "$cache.zwc"
      fi
    } always {
      exec {fd}>&-
    }
  fi
  source "$cache"
}

# Updated tools may emit different `eval "$(tool init)"` output, so `yay` and
# `build` drop the evalcaches and the next shell regenerates them
_evalcache_clear() {
  rm -f "$ZSH_EVALCACHE_DIR"/init-*(N)
}

# Update oh-my-zsh automatically without asking
zstyle ':omz:update' mode auto  

# Load the personal ssh identity up front; ~/.ssh/config adds the others on first
# use (AddKeysToAgent)
zstyle ':omz:plugins:ssh-agent' identities id_ed25519_personal
zstyle ':omz:plugins:ssh-agent' quiet yes

zstyle ':antidote:bundle:*' zcompile 'yes'

# --height matches atuin's inline_height. The label lives here rather than in
# FZF_DEFAULT_OPTS, which zoxide's `zi` and plain fzf read as well
zstyle ':fzf-tab:*' fzf-flags --height=15 --border-label=' Completions '
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# `fzf` on PATH is a mise shim (claudecode.nvim pins its own fzf) that spends ~90ms
# falling back to Homebrew's outside that project, on every completion
zstyle ':fzf-tab:*' fzf-command /opt/homebrew/bin/fzf

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# Wrap the widgets once, when the plugin loads, instead of re-binding all ~600 of
# them on every precmd (~5ms). .zplugins loads it after every other plugin that
# defines widgets, so nothing ends up unwrapped
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# Lazy-load antidote from its functions directory.
fpath=(/opt/homebrew/opt/antidote/share/antidote/functions $fpath)
autoload -Uz antidote

# Regenerate the static bundle whenever .zplugins changes, then source it. Built
# under a temp name and moved in only on success: a failed clone makes antidote
# emit an empty bundle, which would count as fresh and never be retried
if [[ ! ~/.zplugins.bundled.zsh -nt ~/.zplugins ]]; then
  antidote bundle <~/.zplugins >|~/.zplugins.bundled.zsh.$$ \
    && mv -f ~/.zplugins.bundled.zsh.$$ ~/.zplugins.bundled.zsh \
    || rm -f ~/.zplugins.bundled.zsh.$$
fi
source ~/.zplugins.bundled.zsh

# use-omz forks `scutil` for this in every shell that doesn't inherit it
export SHORT_HOST

# Force zsh not to show completion menu, which allows fzf-tab to capture the
# unambiguous prefix. omz's lib/completion.zsh sets `menu select` under this more
# specific pattern, which outranks ':completion:*', so match it after the bundle
zstyle ':completion:*:*:*:*:*' menu no

# omz URL-encodes $PWD (two subshell forks) on every prompt; cache the escape
# sequence per $PWD but still emit it each prompt, so the terminal's recorded
# cwd survives `reset` and tmux reattach. omz neither defines nor hooks the
# function over SSH or in a terminal without OSC 7, so there's nothing to wrap
if (( $+functions[omz_termsupport_cwd] )); then
  functions -c omz_termsupport_cwd _omz_termsupport_cwd_orig
  omz_termsupport_cwd() {
    if [[ $PWD != $_termsupport_cwd_last ]]; then
      typeset -g _termsupport_cwd_last=$PWD
      typeset -g _termsupport_cwd_seq=$(_omz_termsupport_cwd_orig)
    fi
    printf '%s' "$_termsupport_cwd_seq"
  }
fi
