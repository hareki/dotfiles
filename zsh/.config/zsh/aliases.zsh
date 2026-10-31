# `..` works through omz's auto_cd. These two replace omz's global aliases of the
# same names, which zsh-patina colors as unknown commands
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

alias gh-p="gh auth switch --hostname github.com --user hareki"
alias gh-t="gh auth switch --hostname github.com --user harvey-tonomo"
