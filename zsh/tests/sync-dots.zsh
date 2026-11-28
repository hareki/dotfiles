# sync-dots with the real stow, on a scratch repo stowed into the scratch HOME: a package removed
# whole, and one whose directory stays behind with only an ignored .DS_Store, leave no links

source "$ZT_LIB/helpers.zsh"
source "$ZT_LIB/repos.zsh"

zt_repos
mkdir -p $ZT_TMP/bin
ln -s /opt/homebrew/bin/stow $ZT_TMP/bin/stow
path=($ZT_TMP/bin $path)

autoload -Uz $ZT_PKG/.config/zsh/functions/{sync-dots,print-header}

# Stow ignores .DS_Store the way stow/.stow-global-ignore makes it, and $HOME/.config holds more
# than links, as a real one does, so stow never folds it into a link of its own
export STOW_REPO=$ZT_TMP/repo
mkdir -p $HOME/.config/other
print -r -- '\.DS_Store' >$HOME/.stow-global-ignore
git init -q $STOW_REPO
print -r -- .DS_Store >$STOW_REPO/.gitignore
for name in kept gone left fresh; do
  mkdir -p $STOW_REPO/$name/.config/$name
  print -r -- $name >$STOW_REPO/$name/.config/$name/file
done
touch $STOW_REPO/left/.config/left/.DS_Store
git -C $STOW_REPO add .gitignore kept gone left && git -C $STOW_REPO commit -qm packages
stow -d $STOW_REPO -t $HOME kept gone left fresh

# gone: removed with its directory. fresh was never added
git -C $STOW_REPO rm -rq gone
rm -rf $STOW_REPO/gone
output=$(sync-dots all 2>&1)
t_eq 'all: exit status' $? 0
t_lines 'all: every package is synced' "$(t_plain =(print -r -- $output))" \
  $'\n======== Syncing fresh ========\n\n======== Syncing kept ========\n\n======== Syncing left ========'
t_ok "all: the removed package's link is gone" test ! -L $HOME/.config/gone
t_eq "all: the packages' links stay" \
  "$(<$HOME/.config/kept/file) $(<$HOME/.config/fresh/file) $(<$HOME/.config/left/file)" \
  'kept fresh left'

# left: removed with its tracked file only, so its directory stays with the ignored .DS_Store
git -C $STOW_REPO rm -rq left
t_lines '--list: the directories git has a file in' "$(sync-dots --list)" $'fresh\nkept'
output=$(sync-dots all 2>&1)
t_eq 'all with a leftover directory: exit status' $? 0
t_lines 'all with a leftover directory: only the packages are synced' \
  "$(t_plain =(print -r -- $output))" $'\n======== Syncing fresh ========\n\n======== Syncing kept ========'
t_ok "all with a leftover directory: its link is gone" test ! -L $HOME/.config/left
t_ok 'all with a leftover directory: what stow did not link stays' test -d $HOME/.config/other

t_eq 'all again: exit status' "$(sync-dots all >/dev/null 2>&1; print $?)" 0

output=$(sync-dots left 2>&1)
t_eq 'a leftover directory by name: exit status' $? 1
t_eq 'a leftover directory by name: the error' $output "'left' is not a package in $STOW_REPO."
t_ok 'a leftover directory by name: stays unlinked' test ! -L $HOME/.config/left

t_done
