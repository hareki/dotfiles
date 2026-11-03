export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR='nvim'
export VISUAL='nvim'
# eza's macOS default is ~/Library/Application Support; in .zshenv for television's previews
export EZA_CONFIG_DIR="$XDG_CONFIG_HOME/eza"
# Unset, every gcloud/bq/gsutil call (and TAB) first runs a python just to vet it (~15ms).
# Any on-request python the SDK accepts will do; a stale path falls back to that probe
CLOUDSDK_PYTHON=/opt/homebrew/opt/python@3.13/libexec/bin/python
[[ -x $CLOUDSDK_PYTHON ]] && export CLOUDSDK_PYTHON || unset CLOUDSDK_PYTHON

# Use MacOS keychain to store secrets; skip when a parent shell already exported them. Both
# lookups run at once, since each waits ~14ms on the keychain (~35ms back to back, ~20ms together)
if [[ -z $MERCURY_API_KEY || -z $ANTHROPIC_API_KEY ]]; then
  { read -r MERCURY_API_KEY <&3; read -r ANTHROPIC_API_KEY <&4 } \
    3< <(security find-generic-password -a "$USER" -s MERCURY_API_KEY -w) \
    4< <(security find-generic-password -a "$USER" -s ANTHROPIC_API_KEY -w)
  export MERCURY_API_KEY ANTHROPIC_API_KEY
fi

# Skip the global rcs (/etc/zshrc forks `locale`), but for /etc/zprofile's path_helper and
# LANG, which deeper shells (tmux panes) inherit. Sourced here so the dirs below land in front
[[ -o login ]] && (( SHLVL == 1 )) && source /etc/zprofile
unsetopt global_rcs

# The SDK dir adds `gcloud components install` binaries (Homebrew links only core commands)
typeset -U path
path=(
  ~/.local/bin/shims ~/.local/opt/bin ~/.local/share/mise/shims
  /opt/homebrew/bin /opt/homebrew/sbin /opt/homebrew/share/google-cloud-sdk/bin
  $path
)
