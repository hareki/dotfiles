

- These are just config files, pleae make sure to install the packages as well

- I use [stow](https://www.gnu.org/software/stow/) to manage my dotfiles, which handles symlinks to ensure that the files in my dotfiles repository stay synchronized with the actual configuration files. I also cooked some util functions to smoothen the process, which you can find at my [lazy-functions](https://github.com/hareki/dotfiles/blob/main/zsh/.zsh/lazy-functions)

- `manual` isn't a package name, it contains configs requiring manual setup instead of using [stow](https://www.gnu.org/software/stow/)

- Major areas include `zsh` and `nvim`
