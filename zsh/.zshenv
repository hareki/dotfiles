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

# The SDK dir adds `gcloud components install` binaries (Homebrew links only the core
# commands); .zprofile and .zshrc re-apply this order after path_helper and brew shellenv
typeset -a user_path=(
  ~/.local/bin/shims ~/.local/opt/bin ~/.local/share/mise/shims ~/.local/bin
  /opt/homebrew/bin /opt/homebrew/sbin /opt/homebrew/share/google-cloud-sdk/bin
)
typeset -U path
path=($user_path $path)

# Skip /etc/zshrc's `locale` fork. A top-level login shell needs /etc/zprofile's path_helper
# first, so .zprofile does this after it; deeper ones (tmux panes) inherit that PATH
[[ -o login ]] && (( SHLVL == 1 )) || unsetopt global_rcs
