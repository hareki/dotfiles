return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    -- Doesn't work properly since bash and zsh although look similar at first, they're not
    -- Lots of false positives
    -- opts.servers.bashls = { filetypes = { "sh", "zsh" } }

    -- Use noice.nvim to do this instead, just keep it commented as a reference
    -- opts.setup["*"] = function(client, bufnr)
    --   vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    --     border = "rounded",
    --   })
    -- end

    return vim.tbl_deep_extend("force", opts, {
      inlay_hints = {
        enabled = false,
      },
      codelens = {
        enabled = false,
      },
      diagnostics = {
        virtual_text = false,
      },
      servers = {
        typos_lsp = {
          cmd_env = { RUST_LOG = "info" },
          init_options = {
            config = "~/.config/typos/typos.toml",
            diagnosticSeverity = "Info",
          },
        },
      },
    })
  end,
}
