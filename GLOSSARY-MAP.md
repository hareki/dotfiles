# Glossary Map

## Contexts

- [Neovim config](./nvim/.config/nvim/GLOSSARY.md): plugins filed by tier and domain, and the modules other tools reach into
- [Tmux config](./tmux/GLOSSARY.md): the status bar, and the snapshots of every session

## Relationships

- **zsh => Tmux config**: `tsave` and `trestore` take and restore snapshots through the snapshot store
- **zsh => Neovim config**: `tsave` reaches each pane's nvim through its entry points before it kills tmux
