---@class plugins.core.lsp.nvim-lspconfig.utils.server_loader
local M = {}

---Load all LSP server configurations from the lsp/ directory
---Iterates through lua files and configures each server via vim.lsp.config.
---@return nil
function M.load_all()
  local lsp_config_path = vim.fn.stdpath('config') .. '/lua/plugins/core/lsp/nvim-lspconfig/lsp'
  for name, file_type in vim.fs.dir(lsp_config_path) do
    if file_type == 'file' and name:match('%.lua$') then
      local server_name = name:gsub('%.lua$', '')
      local config = require('plugins.core.lsp.nvim-lspconfig.lsp.' .. server_name)

      local opts = config.opts
      if type(opts) == 'function' then
        opts = opts()
      end

      -- Configure the LSP server
      vim.lsp.config(server_name, opts)

      -- Run setup if provided
      if config.setup then
        config.setup()
      end
    end
  end
end

return M
