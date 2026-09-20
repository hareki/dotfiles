# /etc/zprofile's path_helper has just moved the system dirs in front of .zshenv's
# PATH order. Re-applied here rather than only in .zshrc, so non-interactive login
# shells (`zsh -lc`) keep the order as well
path=($user_path $path)
