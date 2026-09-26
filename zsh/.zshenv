# Precompile zshrc (if necessary) before executing it; only interactive shells read it.
# Compiled under a per-shell name and moved in, like _evalcache: shells that start
# together (tmuxinator) collide on zcompile's create of a shared .zwc, and a shell
# sourcing a half-written one can crash
if [[ -o interactive && ( ! -f ~/.zshrc.zwc || ~/.zshrc -nt ~/.zshrc.zwc ) ]]; then
  zcompile ~/.zshrc.$$.zwc ~/.zshrc && mv -f ~/.zshrc.$$.zwc ~/.zshrc.zwc
fi

export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR='nvim'
export VISUAL='nvim'
# eza's own default on macOS is ~/Library/Application Support; set here so the
# eza alias below gets the theme in non-interactive shells too
export EZA_CONFIG_DIR="$XDG_CONFIG_HOME/eza"
# Without it, every gcloud/bq/gsutil call (and TAB) first spawns python3.14,
# python3.13, ... through the mise shims to find a supported version (~125ms).
# This is the interpreter the gcloud-cli cask installs with; bump it along with
# the cask's python dependency (a stale path falls back to that probe)
[[ -x /opt/homebrew/opt/python@3.14/libexec/bin/python ]] \
  && export CLOUDSDK_PYTHON=/opt/homebrew/opt/python@3.14/libexec/bin/python

# Use MacOS keychain to store secrets; skip when a parent shell already exported the value
[[ -n $MERCURY_API_KEY ]] || export MERCURY_API_KEY=$(security find-generic-password -a "$USER" -s "MERCURY_API_KEY" -w)
[[ -n $ANTHROPIC_API_KEY ]] || export ANTHROPIC_API_KEY=$(security find-generic-password -a "$USER" -s "ANTHROPIC_API_KEY" -w)

# Aliases needed in non-interactive shells, others should go into aliases.zsh for performance
alias eza='eza --icons=always --color=always --no-user'
alias fdt='fd --type dir --hidden --exclude .git'
# Prevent fd from taking 100% CPU for long-running searches
alias fd='gtimeout 5s fd'

# PATH for every zsh, highest precedence first: same-name wrappers, tools that
# `build` installs, mise, Homebrew, then `gcloud components install` binaries
# (Homebrew links only the SDK's core commands). In login shells /etc/zprofile's
# path_helper runs after this file and moves the system dirs in front, so .zprofile
# re-applies the list; brew shellenv prepends Homebrew, so .zshrc does too
typeset -a user_path=(
  ~/.local/bin/shims ~/.local/opt/bin ~/.local/share/mise/shims ~/.local/bin
  /opt/homebrew/bin /opt/homebrew/sbin /opt/homebrew/share/google-cloud-sdk/bin
)
typeset -U path
path=($user_path $path)
