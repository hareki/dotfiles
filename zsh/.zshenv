export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR='nvim'
export VISUAL='nvim'
# eza's own default on macOS is ~/Library/Application Support; set here so eza finds
# the theme in non-interactive shells too (television's previews)
export EZA_CONFIG_DIR="$XDG_CONFIG_HOME/eza"
# Unset, every gcloud/bq/gsutil call (and TAB) first runs a python just to vet it (~15ms).
# Any on-request python the SDK accepts will do; a stale path falls back to that probe
CLOUDSDK_PYTHON=/opt/homebrew/opt/python@3.13/libexec/bin/python
[[ -x $CLOUDSDK_PYTHON ]] && export CLOUDSDK_PYTHON || unset CLOUDSDK_PYTHON

# Use MacOS keychain to store secrets; skip when a parent shell already exported the value
[[ -n $MERCURY_API_KEY ]] || export MERCURY_API_KEY=$(security find-generic-password -a "$USER" -s "MERCURY_API_KEY" -w)
[[ -n $ANTHROPIC_API_KEY ]] || export ANTHROPIC_API_KEY=$(security find-generic-password -a "$USER" -s "ANTHROPIC_API_KEY" -w)

# Skip the global rcs (/etc/zshrc forks `locale`), but for /etc/zprofile's path_helper and
# LANG, which deeper shells (tmux panes) inherit. Sourced here so user_path lands in front
[[ -o login ]] && (( SHLVL == 1 )) && source /etc/zprofile
unsetopt global_rcs

# The SDK dir adds `gcloud components install` binaries (Homebrew links only the core
# commands); plugins.zsh re-applies this order after brew shellenv
typeset -a user_path=(
  ~/.local/bin/shims ~/.local/opt/bin ~/.local/share/mise/shims ~/.local/bin
  /opt/homebrew/bin /opt/homebrew/sbin /opt/homebrew/share/google-cloud-sdk/bin
)
typeset -U path
path=($user_path $path)
