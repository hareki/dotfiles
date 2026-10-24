# /etc/zprofile's path_helper has just moved the system dirs in front. Re-applied here,
# not only in .zshrc, so non-interactive login shells (`zsh -lc`) keep the order too
path=($user_path $path)

# Skip /etc/zshrc now that /etc/zprofile has run (see .zshenv)
unsetopt global_rcs
