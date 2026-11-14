--- @class features.formatting.conform-nvim.style-enforcer.oxlint: features.formatting.conform-nvim.style-enforcer.Step
local M = {
  name = 'oxlint',
  label = 'Fixing (oxlint)',
  kind = 'fix',
  client = 'oxlint',
}

--- Run oxc.fixAll on a buffer through the oxlint language server
--- @param ctx features.formatting.conform-nvim.style-enforcer.LspContext
--- @return nil
function M.run(ctx)
  local document = vim.lsp.util.make_text_document_params(ctx.buf)

  -- oxc.fixAll replays the server's last lint as an unversioned edit, and the format step's
  -- didChange doesn't re-lint, so pull diagnostics first or stale fixes would corrupt the text
  ctx.request('textDocument/diagnostic', { textDocument = document }, function()
    ctx.execute('oxc.fixAll', document)
  end)
end

return M
