# Glossary Map

## Contexts

- [Neovim config](./nvim/.config/nvim/GLOSSARY.md): plugins filed by tier and domain, and the modules other tools reach into
- [Tmux config](./tmux/GLOSSARY.md): the status bar, and the snapshots of every session
- [Zsh config](./zsh/GLOSSARY.md): the startup, the commands built on it, and their tests

## Relationships

- **Zsh config => Tmux config**: `tsave` and `trestore` take and restore snapshots through the snapshot store
- **Zsh config => Neovim config**: `tsave` reaches each pane's nvim through its entry points before it kills tmux
