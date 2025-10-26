alias lg="lazygit"
alias ff="fastfetch"
alias brewup='brew update && brew upgrade && brew autoremove && brew cleanup'

alias cd="z"
alias nvim="nvcd"
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

# --login is to make sure the new shell behaves exactly like the first time we open the terminal
# -i to ignore all current environment variables, must set the $TERM in .zprofile/.zshenv
alias rez="clear && exec env -i zsh --login"