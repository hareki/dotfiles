--- @class core.lsp.nvim-lspconfig.utils.server-loader
local M = {}

--- Load all LSP server configurations from the lsp/ directory
--- @return nil
function M.load_all()
  -- The lister behind lazy.nvim's `import`, so the directory is named once, as a module path
  local lazy_util = require('lazy.core.util')
  lazy_util.lsmod('core.lsp.nvim-lspconfig.lsp', function(modname)
    local server_name = modname:match('[^.]+$')
    local config = require(modname)

    vim.lsp.config(server_name, config.opts)

    if config.setup then
      config.setup()
    end
  end)
end

return M
