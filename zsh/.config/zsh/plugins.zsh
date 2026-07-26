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
    "$@" >"$cache" || { rm -f "$cache"; print -u2 "_evalcache: '$*' failed"; return 1 }
    zcompile "$cache"
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

# omz re-encodes and re-emits OSC 7 on every prompt; skip when $PWD is unchanged
functions -c omz_termsupport_cwd _omz_termsupport_cwd_orig
omz_termsupport_cwd() {
  [[ $PWD == $_termsupport_cwd_last ]] && return
  typeset -g _termsupport_cwd_last=$PWD
  _omz_termsupport_cwd_orig
}

