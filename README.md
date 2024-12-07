<div>
  <img src="https://socialify.git.ci/hareki/dotfiles/image?font=Source%20Code%20Pro&language=1&name=1&owner=1&pattern=Solid&theme=Auto">
</div>

<hr>

> [!Note]
> - These are just config files, pleae make sure to install the packages as well
> - `manual` isn't a package name, it contains configs requiring manual setup instead of using `stow`
> - I sometimes use `sync-g` to quickly commit my changes, so pardon those weird commit messages if you see them

I use [stow](https://www.gnu.org/software/stow/) to manage my dotfiles, which handles symlinks to ensure that the files in my dotfiles repository stay synchronized with the actual configuration files.

<details><summary>I even took step further and created some util functions to smoothen the process, which you can find at my <a href="https://github.com/hareki/dotfiles/blob/main/zsh/.zsh/lazy-functions">lazy-functions</a></summary>

<!-- config:start -->
  
```shell
# NOTE: Stow config
export STOW_REPO="$HOME/Repositories/personal/dotfiles"
# [S]ync-[D]otfiles
sync-d() {
    if [ -d "$STOW_REPO/$1" ]; then
        z "$STOW_REPO" || return
        stow "$1" -t ~
        z -  > /dev/null
    else
        echo "Directory $STOW_REPO/$1 does not exist."
    fi
}

_sync_d_autocomplete() {
    local -a dirs
    local repo_dir="$STOW_REPO"

    # Get a list of directories under $STOW_REPO excluding .git and feed them into completion
    dirs=(${(f)"$(fd --type d --max-depth 1 --exclude .git --base-directory $repo_dir --exec basename {})"})
    _describe 'stow directories' dirs
}
compdef _sync_d_autocomplete sync-d

# [S]ync [G]itHub
sync-g() {
  z "$STOW_REPO" || return
  
  # Check for uncommitted changes
  if git status --porcelain | grep -q .; then
    git add .
    git commit -m "Updated via sync-g at $(date +"%d/%m/%Y | %a %I:%M %p")"
    git push
  else
    # No uncommitted changes, check for unpushed commits
    if git log --branches --not --remotes | grep -q .; then
      echo "Unpushed commits found. Pushing now..."
      git push
    else
      echo "Nothing to commit, working tree clean, and all changes are pushed."
    fi
  fi

  z - || return
}
```

<!-- config:end -->

</details>
