# `..` works through omz's auto_cd. These two replace omz's global aliases of the
# same names, which zsh-patina colors as unknown commands
alias ...="cd ../.."
alias ....="cd ../../.."

alias compz="zcompile ~/.zshrc"
alias cl="clear"
alias cc="claude"
alias nv="nvim"
alias lg="lazygit"

alias ez="nvim ~/.zshrc"
alias eze="nvim ~/.zshenv"

alias tree="eza --tree"
alias submodule-update="git submodule update --init --recursive --remote"
