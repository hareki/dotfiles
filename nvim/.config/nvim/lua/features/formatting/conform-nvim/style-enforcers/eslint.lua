--- @class features.formatting.conform-nvim.style-enforcers.eslint: features.formatting.conform-nvim.style-enforcers.Step
local M = {
  name = 'eslint',
  label = 'Fixing (eslint)',
  kind = 'fix',
  client = 'eslint',
}

--- Run eslint.applyAllFixes on a buffer through the eslint language server
--- @param ctx features.formatting.conform-nvim.style-enforcers.LspContext
--- @return nil
function M.run(ctx)
  ctx.execute('eslint.applyAllFixes', {
    uri = vim.uri_from_bufnr(ctx.buf),
    version = vim.lsp.util.buf_versions[ctx.buf],
  })
end

return M
