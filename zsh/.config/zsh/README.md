- Blazingly fast ZSH startup (~110ms) yet packed with features
- Clean and organized dotfiles structure

## Performance Optimization

This configuration leverages several advanced techniques to maintain speed:

### Lazy Loading & Caching

- **[Antidote](https://github.com/mattmc3/antidote)**: Modern plugin manager that statically generates and defer plugin loading code for optimal performance
- **[evalcache](https://github.com/mroth/evalcache)**: Caches the output of shell commands to avoid repeated initialization
- **ZSH zcompile**: Precompiles script files to bytecode for faster loading
- **Autoload**: Defers loading functions until they're actually needed

```bash
# Precompiles zshrc for faster loading
[[ ! -f ~/.zshrc.zwc || ~/.zshrc -nt ~/.zshrc.zwc ]] && zcompile ~/.zshrc

#--------------------

# Autoload util functions when needed
functions_dir=$__zsh_config_dir/functions
fpath=($functions_dir $fpath)
for func in $functions_dir/*(.N); do
  autoload -Uz "${func:t}"
done

#--------------------

# Static plugin generation with Antidote
if [[ ! ${bundled_zsh_plugins} -nt ${zsh_plugins} ]]; then
  antidote bundle <${zsh_plugins} >|${bundled_zsh_plugins}
fi

#--------------------

# Caching eval results
_evalcache /opt/homebrew/bin/brew shellenv
_evalcache mise activate zsh
_evalcache zoxide init zsh
_evalcache vivid_ls catppuccin-mocha
```

## Features

### Plugins

- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions): Command suggestions based on history
- [zsh-interactive-cd](https://github.com/zsh-users/zsh-interactive-cd): An interactive way to change directories in zsh using fzf
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting): Syntax highlighting as you type
- [powerlvel10k](https://github.com/romkatv/powerlevel10k): Performant and feature-rich prompt theme

### Utilities

- See [functions.zsh](./.config/zsh/functions) for a comprehensive list of utility functions
