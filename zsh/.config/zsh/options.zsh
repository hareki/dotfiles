# [[ Settings ENV variables that are not needed outside interactive shells ]]
# History settings come from omz's lib/history.zsh

export REPOS_DIR="$HOME/Repositories/personal"
export STOW_REPO="$REPOS_DIR/dotfiles"
unset EZA_COLORS LS_COLORS # Centralize eza theme config (EZA_CONFIG_DIR, set in .zshenv)

# Don't mark output that lacks a trailing newline with a highlighted %
# https://unix.stackexchange.com/questions/167582/why-zsh-ends-a-line-with-a-highlighted-percent-symbol
PROMPT_EOL_MARK=''

# FZF Catppuccin Mocha color
export FZF_DEFAULT_OPTS=" \
--border=rounded --layout=reverse --cycle --info=inline-right --info-command='echo \"\${FZF_MATCH_COUNT}/\${FZF_TOTAL_COUNT}\"' --pointer='' --highlight-line \
--preview-window noinfo --scrollbar '' --prompt='  ' \
--color=bg+:#313244,spinner:#f5e0dc,hl:#89b4fa,border:#89b4fa \
--color=fg:#cdd6f4,header:#f38ba8,info:#6c7086,pointer:#f5e0dc,label:#89b4fa::bold \
--color=marker:#89b4fa,fg+:#cdd6f4:regular,prompt:#89b4fa,hl+:#89b4fa:regular,query::regular \
--height=15 --margin=0,1 \
--bind page-up:preview-half-page-up \
--bind page-down:preview-half-page-down \
--bind esc:abort \
--multi"

# Zoxide specific options
export _ZO_FZF_OPTS="$FZF_DEFAULT_OPTS"
