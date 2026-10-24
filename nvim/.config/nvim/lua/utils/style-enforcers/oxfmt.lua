local engine = require('utils.style-enforcers.engine')

--- @class utils.style-enforcers.oxfmt
local M = {}

--- Format a buffer in memory with the oxfmt language server's edits (no CLI spawn)
--- @param opts { bufnr: integer, client: vim.lsp.Client, on_done: fun(ok: boolean, err?: string) }
--- @return nil
function M.run(opts)
  local bufnr = opts.bufnr
  local oxfmt = opts.client

  -- make_formatting_params reads tabSize/insertSpaces from the current buffer,
  -- which is not necessarily the target buffer (run_all formats in background)
  local params = vim.api.nvim_buf_call(bufnr, vim.lsp.util.make_formatting_params)
  params.textDocument = { uri = vim.uri_from_bufnr(bufnr) }
  local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)

  oxfmt:request('textDocument/formatting', params, function(err, result)
    if err then
      return opts.on_done(false, err.message)
    end

    -- The edits carry no document version, so after an edit made while the request was in flight
    -- (typing on after <A-s>) they'd land at shifted positions and corrupt the text: discard them
    if
      not vim.api.nvim_buf_is_valid(bufnr)
      or vim.api.nvim_buf_get_changedtick(bufnr) ~= changedtick
    then
      return opts.on_done(false, engine.BUFFER_CHANGED)
    end

    if result then
      vim.lsp.util.apply_text_edits(result, bufnr, oxfmt.offset_encoding)
    end

    opts.on_done(true)
  end, bufnr)
end

return M
