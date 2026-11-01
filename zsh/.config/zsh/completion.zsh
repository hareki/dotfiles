# Sourced after vi-mode, since compinit binds its `^X` keys in the main keymap, and before
# evals, whose tools call compdef
fpath=($__zsh_config_dir/compdefs $fpath)
# A changed fpath dir has a new mtime, which spares compinit's own check (-C) its glob of
# every `_*` file (~5ms)
ZSH_COMPDUMP=$ZSH_CACHE_DIR/zcompdump-$ZSH_VERSION
() {
  local dir
  for dir in $fpath; do
    [[ $dir -nt $ZSH_COMPDUMP ]] && rm -f $ZSH_COMPDUMP
  done
}
autoload -Uz compinit && compinit -C -d $ZSH_COMPDUMP
if [[ ! $ZSH_COMPDUMP.zwc -nt $ZSH_COMPDUMP ]]; then
  zcompile $ZSH_COMPDUMP.$$.zwc $ZSH_COMPDUMP && mv -f $ZSH_COMPDUMP.$$.zwc $ZSH_COMPDUMP.zwc
fi

# fzf-tab needs zsh's menu off to capture the unambiguous prefix; omz sets `menu select`
# under this pattern, which outranks ':completion:*', so this must follow the bundle
zstyle ':completion:*:*:*:*:*' menu no
