# Glossary Map

## Contexts

- [Lazygit config](./lazygit/GLOSSARY.md): the edit commands, and codediff, the diff renderer: how it is served and the tests that pin what it shows
- [Neovim config](./nvim/.config/nvim/GLOSSARY.md): plugins filed by tier and domain, and the modules other tools reach into
- [Zsh config](./zsh/GLOSSARY.md): the startup, the commands built on it, and their tests

## Relationships

- **Lazygit config => Neovim config**: codediff takes its filetype rules and capture colors from the editor's entry points, and lazygit's edit commands reach the nvim it runs inside through one
