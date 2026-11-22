# Language servers

How a language server is enabled and configured, and which servers run in which project. Paths below are under `core/lsp/nvim-lspconfig/`.

## Enabling and configuring

- Enable a server in the `servers` list in `init.lua`; add a `lsp/{server}.lua` only to override nvim-lspconfig's defaults.
- Each `lsp/{server}.lua` returns `{ opts = table, setup = function? }`, **not a lazy.nvim spec or a raw `vim.lsp.Config`**: `utils/server-loader.lua` requires every file only once nvim-lspconfig loads (so computed values are plain file-level locals), then calls `vim.lsp.config(name, opts)` and `setup()` if present.
- General LSP keymaps live in `init.lua`, not server files; diagnostics display and the severity jumps live in `features/diagnostics/vim-diagnostic/`.
- Server-specific `LspAttach` autocmds use an early-return guard on client name (see `utils/typescript.lua`).

## Servers chosen per project

- `eslint`, `oxlint` and `oxfmt` are always in `servers` and pick their projects per buffer: `root_dir` looks for each tool's own config, and `workspace_required` keeps them off everywhere else. conform's prettier `condition` asks oxfmt's `root_dir`, so oxfmt projects never run prettier.
- Those three drive style-enforcer steps and are named by server id in their step's `client` field (`features/formatting/conform-nvim/style-enforcer/{eslint,oxlint,oxfmt}.lua`), which limits each step to buffers that server is attached to. A new server that formats or fixes on save needs the same.
- `vtsls` and `tsc` are both in `servers`, and `utils/typescript.lua` activates one per project from its TypeScript: `tsc` for 7+, `vtsls` otherwise. A project that declares 7+ without installing it gets neither, never `vtsls`'s bundled TypeScript.
