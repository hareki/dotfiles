local engine = require('features.formatting.conform-nvim.style-enforcers.engine')

--- @class features.formatting.conform-nvim.style-enforcers.eslint
local M = {}

--- Run eslint.applyAllFixes on a buffer through the eslint language server
--- @param opts features.formatting.conform-nvim.style-enforcers.engine.RunnerOpts
--- @return nil
function M.run(opts)
  engine.execute_command(opts, 'eslint.applyAllFixes', {
    uri = vim.uri_from_bufnr(opts.bufnr),
    version = vim.lsp.util.buf_versions[opts.bufnr],
  })
end

return M
