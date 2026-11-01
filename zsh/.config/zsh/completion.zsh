# Sourced after vi-mode, since compinit binds its `^X` keys in the main keymap, and before
# evals, whose tools call compdef
fpath=($XDG_CONFIG_HOME/zsh/compdefs $fpath)
# A changed fpath dir has a new mtime, which spares compinit's own check (-C) its glob of
# every `_*` file (~5ms)
ZSH_COMPDUMP=$ZSH_CACHE_DIR/zcompdump-$ZSH_VERSION
() {
  local dir
  for dir in $fpath; do
    [[ $dir -nt $ZSH_COMPDUMP ]] && rm -f $ZSH_COMPDUMP
  done
}

# _git is 388KB of zsh: ~95ms to parse on a shell's first `git <TAB>`, and in every async
# suggestion that reaches the completion strategy. -U: aliases mustn't expand at compile time
if [[ ! -e $ZSH_CACHE_DIR/_git.zwc ]]; then
  zcompile -U $ZSH_CACHE_DIR/_git.$$.zwc $^fpath/_git(N) \
    && mv -f $ZSH_CACHE_DIR/_git.$$.zwc $ZSH_CACHE_DIR/_git.zwc
fi
# Ahead of compinit, as this path is ignored once a plain autoload has marked the function.
# -d falls back to fpath, since an update can leave a digest the running zsh can't read
autoload -dUz $ZSH_CACHE_DIR/_git

autoload -Uz compinit && compinit -C -d $ZSH_COMPDUMP
if [[ ! $ZSH_COMPDUMP.zwc -nt $ZSH_COMPDUMP ]]; then
  zcompile $ZSH_COMPDUMP.$$.zwc $ZSH_COMPDUMP && mv -f $ZSH_COMPDUMP.$$.zwc $ZSH_COMPDUMP.zwc
fi

# fzf-tab needs zsh's menu off to capture the unambiguous prefix; omz sets `menu select`
# under this pattern, which outranks ':completion:*', so this must follow the bundle
zstyle ':completion:*:*:*:*:*' menu no
