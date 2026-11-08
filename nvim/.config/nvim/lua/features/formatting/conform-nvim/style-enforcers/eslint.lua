--- @class features.formatting.conform-nvim.style-enforcers.eslint: features.formatting.conform-nvim.style-enforcers.Step
local M = {
  name = 'eslint',
  label = 'Linting (eslint)',
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

--- @param err string
--- @param debug? boolean
--- @return features.formatting.conform-nvim.style-enforcers.Failure
function M.failure(err, debug)
  return {
    level = 'warn',
    title = 'Linting Failed',
    msg = debug and string.format('Linter eslint error: %s', err) or 'Linter used: eslint',
  }
end

return M
