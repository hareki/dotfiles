--- @class features.formatting.conform-nvim.style-enforcers.oxfmt: features.formatting.conform-nvim.style-enforcers.Step
local M = {
  name = 'oxfmt',
  label = 'Formatting (oxfmt)',
  client = 'oxfmt',
}

--- Format a buffer in memory with the oxfmt language server's edits (no CLI spawn)
--- @param ctx features.formatting.conform-nvim.style-enforcers.LspContext
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

--- @param err string
--- @param debug? boolean
--- @return features.formatting.conform-nvim.style-enforcers.Failure
function M.failure(err, debug)
  return {
    level = 'error',
    title = 'Formatting Failed',
    msg = debug and string.format('Formatter oxfmt error: %s', err) or 'Formatter used: oxfmt',
  }
end

return M
