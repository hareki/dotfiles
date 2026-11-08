--- @class features.formatting.conform-nvim.style-enforcers.oxlint: features.formatting.conform-nvim.style-enforcers.Step
local M = {
  name = 'oxlint',
  label = 'Linting (oxlint)',
  client = 'oxlint',
}

--- Run oxc.fixAll on a buffer through the oxlint language server
--- @param ctx features.formatting.conform-nvim.style-enforcers.LspContext
--- @return nil
function M.run(ctx)
  local document = vim.lsp.util.make_text_document_params(ctx.buf)

  -- oxc.fixAll replays the server's last lint as an unversioned edit, and the format step's
  -- didChange doesn't re-lint, so pull diagnostics first or stale fixes would corrupt the text
  ctx.request('textDocument/diagnostic', { textDocument = document }, function()
    ctx.execute('oxc.fixAll', document)
  end)
end

--- @param err string
--- @param debug? boolean
--- @return features.formatting.conform-nvim.style-enforcers.Failure
function M.failure(err, debug)
  return {
    level = 'warn',
    title = 'Linting Failed',
    msg = debug and string.format('Linter oxlint error: %s', err) or 'Linter used: oxlint',
  }
end

return M
