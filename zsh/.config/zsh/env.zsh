# [[ Settings ENV variables that are not needed outside interactive shells ]]

export STOW_REPO="$HOME/Repositories/personal/dotfiles"
export TEALDEER_CONFIG_DIR="$XDG_CONFIG_HOME/tealdeer"
export EZA_CONFIG_DIR="$XDG_CONFIG_HOME/eza"
unset EZA_COLORS LS_COLORS # Centralize eza theme config

# Make sure ImageMagick work properly in image.nvim
export DYLD_FALLBACK_LIBRARY_PATH="/opt/homebrew/lib:$DYLD_FALLBACK_LIBRARY_PATH"

# Prevent the dollar sign at the start when restoring sessions with tmux-resurrect
# https://unix.stackexchange.com/questions/167582/why-zsh-ends-a-line-with-a-highlighted-percent-symbol
export PROMPT_EOL_MARK=''

# Zoxide specific options 
export _ZO_FZF_OPTS="--height=45%"
export _ZO_FZF_OPTS="$_ZO_FZF_OPTS $FZF_DEFAULT_OPTS"

# FZF Catppuccin Mocha color
export FZF_DEFAULT_OPTS=" \
--border=rounded --layout=reverse --cycle --info=inline-right --info-command='echo \"\${FZF_MATCH_COUNT}/\${FZF_TOTAL_COUNT}\"' --pointer='' --highlight-line \
--preview-window noinfo --scrollbar '' --prompt='  ' \
--color=bg+:#313244,gutter:#1e1e2e,bg:#1e1e2e,spinner:#f5e0dc,hl:#89b4fa,border:#89b4fa \
--color=fg:#cdd6f4,header:#f38ba8,info:#6c7086,pointer:#f5e0dc,label:#89b4fa::bold \
--color=marker:#89b4fa,fg+:#cdd6f4:regular,prompt:#89b4fa,hl+:#89b4fa:regular,query::regular \
--color=selected-bg:#1e1e2e \
--bind page-up:preview-half-page-up \
--bind page-down:preview-half-page-down \
--bind esc:abort \
--border-label ' Fzf Suggestions ' \
--multi"
