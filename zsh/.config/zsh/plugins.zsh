export ZSH_EVALCACHE_DIR="$HOME/.cache/.zsh-evalcache"
export ANTIDOTE_HOME="$HOME/.cache/antidote"

# Cache expensive `eval "$(cmd)"` output; invalidate by deleting the cache
# file (`yay` and `build`).
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
        # shell can't read (or SIGBUS on) a half-written file, and `yay`/
        # `build`'s `rm init-*` can't delete them mid-build. The two-arg
        # zcompile records the source path, not the output name, so the
        # renamed .zwc stays valid.
        local tmp="${cache:h}/.${cache:t}.$$"
        "$@" >"$tmp" || { rm -f "$tmp"; print -u2 "_evalcache: '$*' failed"; return 1 }
        mv -f "$tmp" "$cache"
        zcompile "$tmp.zwc" "$cache" && mv -f "$tmp.zwc" "$cache.zwc"
      fi
    } always {
      [[ -n $fd ]] && exec {fd}>&-
    }
  fi
  source "$cache"
}

# Update oh-my-zsh automatically without asking
zstyle ':omz:update' mode auto  

# Load multiple ssh agent identities
zstyle ':omz:plugins:ssh-agent' identities id_ed25519_personal id_ed25519_zigvy
zstyle ':omz:plugins:ssh-agent' quiet yes

zstyle ':antidote:bundle:*' zcompile 'yes'

zstyle ':fzf-tab:*' fzf-flags --height=15 # Match atuin config inline_height
zstyle ':fzf-tab:*' use-fzf-default-opts yes

# Force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no

ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Set the root name of the plugins files (.txt and .zsh) antidote will use.
zsh_plugins="$HOME/.zplugins"
bundled_zsh_plugins="${zsh_plugins}.bundled.zsh"

# Lazy-load antidote from its functions directory.
fpath=(/opt/homebrew/opt/antidote/share/antidote/functions $fpath)
autoload -Uz antidote

# Generate a new static file whenever .zplugins is updated.
if [[ ! ${bundled_zsh_plugins} -nt ${zsh_plugins} ]]; then
  antidote bundle <${zsh_plugins} >|${bundled_zsh_plugins}
fi

# Source your static plugins file.
source ${bundled_zsh_plugins}

# omz URL-encodes $PWD (two subshell forks) on every prompt; cache the escape
# sequence per $PWD but still emit it each prompt, so the terminal's recorded
# cwd survives `reset` and tmux reattach
functions -c omz_termsupport_cwd _omz_termsupport_cwd_orig
omz_termsupport_cwd() {
  if [[ $PWD != $_termsupport_cwd_last ]]; then
    typeset -g _termsupport_cwd_last=$PWD
    typeset -g _termsupport_cwd_seq=$(_omz_termsupport_cwd_orig)
  fi
  printf '%s' "$_termsupport_cwd_seq"
}
