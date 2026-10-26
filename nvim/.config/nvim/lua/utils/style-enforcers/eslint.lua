local engine = require('utils.style-enforcers.engine')

--- @class utils.style-enforcers.eslint
local M = {}

--- Run eslint.applyAllFixes on a buffer through the eslint language server
--- @param opts utils.style-enforcers.RunnerOpts
--- @return nil
function M.run(opts)
  engine.execute_command(opts, 'eslint.applyAllFixes', {
    uri = vim.uri_from_bufnr(opts.bufnr),
    version = vim.lsp.util.buf_versions[opts.bufnr],
  })
end

return M
