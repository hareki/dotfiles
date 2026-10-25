# Compiled under a per-shell name and moved in: shells that start together (tmuxinator)
# collide creating a shared .zwc, and sourcing a half-written one can crash
if [[ -o interactive && ! ~/.zshrc.zwc -nt ~/.zshrc ]]; then
  zcompile ~/.zshrc.$$.zwc ~/.zshrc && mv -f ~/.zshrc.$$.zwc ~/.zshrc.zwc
fi

export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR='nvim'
export VISUAL='nvim'
# eza's own default on macOS is ~/Library/Application Support; set here so the
# eza alias below gets the theme in non-interactive shells too
export EZA_CONFIG_DIR="$XDG_CONFIG_HOME/eza"
# Unset, every gcloud/bq/gsutil call (and TAB) probes python3.14, 3.13, ... through
# the mise shims (~125ms). Bump it with the gcloud-cli cask's python dependency
CLOUDSDK_PYTHON=/opt/homebrew/opt/python@3.13/libexec/bin/python
[[ -x $CLOUDSDK_PYTHON ]] && export CLOUDSDK_PYTHON || unset CLOUDSDK_PYTHON

# Use MacOS keychain to store secrets; skip when a parent shell already exported the value
[[ -n $MERCURY_API_KEY ]] || export MERCURY_API_KEY=$(security find-generic-password -a "$USER" -s "MERCURY_API_KEY" -w)
[[ -n $ANTHROPIC_API_KEY ]] || export ANTHROPIC_API_KEY=$(security find-generic-password -a "$USER" -s "ANTHROPIC_API_KEY" -w)

# Aliases needed in non-interactive shells (television runs its cable commands
# through `$SHELL -c`), others should go into aliases.zsh for performance
alias eza='eza --icons=always --color=always --no-user'
alias fdt='fd --type dir --hidden --exclude .git'

# The SDK dir adds `gcloud components install` binaries (Homebrew links only the core
# commands); .zprofile and .zshrc re-apply this order after path_helper and brew shellenv
typeset -a user_path=(
  ~/.local/bin/shims ~/.local/opt/bin ~/.local/share/mise/shims ~/.local/bin
  /opt/homebrew/bin /opt/homebrew/sbin /opt/homebrew/share/google-cloud-sdk/bin
)
typeset -U path
path=($user_path $path)

# Skip /etc/zshrc, which forks `locale` in every interactive shell. Login shells still
# need /etc/zprofile's path_helper, so .zprofile turns global_rcs off after it
[[ -o login ]] || unsetopt global_rcs
