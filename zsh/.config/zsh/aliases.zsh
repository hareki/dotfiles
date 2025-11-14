alias lg="lazygit"
alias ff="fastfetch"
alias yay='brew update && brew upgrade && brew autoremove && npm update -g'

alias cd="z"
alias cdi="zi"
alias ..="z .."
alias ...="z ..."
alias ....="z ...."

alias yazi="ycd"
alias profile="time ZSH_DEBUGRC=1 zsh -i -c exit"
alias compz="zcompile ~/.zshrc"
alias cl="clear"
alias ez="nvim ~/.zshrc"
alias eze="nvim ~/.zshenv"

# [RE-Z]shrc
# env -i ... is to hard reset the environment variables to empty, must retain the essential ones like TERM
# this is to make sure the new zsh instance that doesn't inherit any of the previously exported variables.
