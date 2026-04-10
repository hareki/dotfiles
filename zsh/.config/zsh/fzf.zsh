# FZF Catppuccin Mocha color
export FZF_DEFAULT_OPTS=" \
--border=rounded --layout=reverse --cycle --info=inline-right --info-command='echo \"\${FZF_MATCH_COUNT}/\${FZF_TOTAL_COUNT}\"' --pointer='' --highlight-line \
--preview-window noinfo --scrollbar '▌▐' --prompt='  ' \
--color=bg+:#313244,gutter:#1e1e2e,bg:#1e1e2e,spinner:#f5e0dc,hl:#89b4fa,border:#89b4fa \
--color=fg:#cdd6f4,header:#f38ba8,info:#6c7086,pointer:#f5e0dc,label:#89b4fa::bold \
--color=marker:#89b4fa,fg+:#cdd6f4,prompt:#89b4fa,hl+:#89b4fa \
--color=selected-bg:#1e1e2e \
--bind page-up:preview-half-page-up \
--bind page-down:preview-half-page-down \
--bind esc:abort \
--border-label ' Fuzzy ' \
--multi"
