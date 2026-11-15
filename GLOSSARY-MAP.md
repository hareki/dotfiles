# Glossary Map

## Contexts

- [Lazygit config](./lazygit/GLOSSARY.md): codediff, the diff renderer, and the tests that pin what it shows
- [Neovim config](./nvim/.config/nvim/GLOSSARY.md): plugins filed by tier and domain, and the modules other tools reach into
- [Tmux config](./tmux/GLOSSARY.md): the status bar, and the snapshots of every session
- [Zsh config](./zsh/GLOSSARY.md): the startup, the commands built on it, and their tests

## Relationships

- **Lazygit config => Neovim config**: codediff takes its filetype rules and capture colors from the editor's entry points, and lazygit's edit commands reach the nvim it runs inside through one
- **Zsh config => Tmux config**: `tsave` and `trestore` take and restore snapshots through the snapshot store
- **Zsh config => Neovim config**: `tsave` reaches each pane's nvim through its entry points before it kills tmux
