# FZF Catppuccin Mocha color
export FZF_DEFAULT_OPTS=" \
--border=rounded --layout=reverse --cycle --info=inline-right --pointer=''  \
--preview-window noinfo --scrollbar '▌▐' --prompt='  ' \
--color=bg+:#1e1e2e,gutter:#1e1e2e,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8,border:#89b4fa \
--color=fg:#cdd6f4,header:#f38ba8,info:#6c7086,pointer:#f5e0dc,labeL:#89b4fa \
--color=marker:#b4befe,fg+:#f5e0dc,prompt:#89b4fa,hl+:#f38ba8 \
--color=selected-bg:#1e1e2e \
--bind page-up:preview-half-page-up \
--bind page-down:preview-half-page-down \
--bind esc:abort \
--border-label ' Fzf ' \
--multi"