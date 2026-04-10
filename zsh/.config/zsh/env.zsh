# [[ Settings ENV variables that are not needed outside interactive shells ]]

# The mise shims path we set in .zshenv is overwritten by homebrew
PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin/shims:$HOME/.local/bin:$PATH"

export STOW_REPO="$HOME/Repositories/personal/dotfiles"
export TEALDEER_CONFIG_DIR="$XDG_CONFIG_HOME/tealdeer"
export EZA_CONFIG_DIR="$XDG_CONFIG_HOME/eza"
unset EZA_COLORS LS_COLORS # Centralize eza theme config

# Make sure ImageMagick work properly in image.nvim
export DYLD_FALLBACK_LIBRARY_PATH="/opt/homebrew/lib:$DYLD_FALLBACK_LIBRARY_PATH"

# Prevent the dollar sign at the start when restoring sessions with tmux-resurrect
# https://unix.stackexchange.com/questions/167582/why-zsh-ends-a-line-with-a-highlighted-percent-symbol
export PROMPT_EOL_MARK=''
