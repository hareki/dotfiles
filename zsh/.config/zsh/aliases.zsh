# Replace omz's global aliases, which zsh-patina colors as unknown commands (`..` is auto_cd)
alias ...="cd ../.."
alias ....="cd ../../.."

alias cl="clear"
alias cc="claude"
alias nv="nvim"
alias lg="lazygit"

alias ez="nvim ~/.zshrc"
alias eze="nvim ~/.zshenv"

alias eza="eza --icons=always --color=always --no-user"
alias fdt="fd --type dir --hidden --exclude .git"
alias tree="eza --tree"
alias submodule-update="git submodule update --init --recursive --remote"
# The subshell keeps zsh-patina from coloring the assignment as a missing command
alias profile='time (ZSH_DEBUGRC=1 zsh -i -c exit)'

alias gh-p="gh auth switch --hostname github.com --user hareki"
alias gh-t="gh auth switch --hostname github.com --user harvey-tonomo"
