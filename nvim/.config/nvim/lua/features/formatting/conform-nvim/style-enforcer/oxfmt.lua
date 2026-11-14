--- @class features.formatting.conform-nvim.style-enforcer.oxfmt: features.formatting.conform-nvim.style-enforcer.Step
local M = {
  name = 'oxfmt',
  label = 'Formatting (oxfmt)',
  kind = 'format',
  client = 'oxfmt',
}

--- Format a buffer in memory with the oxfmt language server's edits (no CLI spawn)
--- @param ctx features.formatting.conform-nvim.style-enforcer.LspContext
--- @return nil
function M.run(ctx)
  -- make_formatting_params reads the current buffer, and run_all formats in the background
  local params = vim.api.nvim_buf_call(ctx.buf, vim.lsp.util.make_formatting_params)

  ctx.request('textDocument/formatting', params, function(result)
    if result then
      vim.lsp.util.apply_text_edits(result, ctx.buf, ctx.client.offset_encoding)
    end

    ctx.done()
  end)
end

return M
