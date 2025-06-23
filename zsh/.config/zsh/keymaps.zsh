zle -N load_fzf_completion
bindkey '^R' load_fzf_completion

zle -N mz_insert_path
bindkey '^O' mz_insert_path

bindkey '^Y' autosuggest-accept