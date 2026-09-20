local engine = require('utils.style-enforcers.engine')

--- @class utils.style-enforcers.oxfmt
local M = {}

--- Run oxfmt formatting on a buffer via LSP
--- Sends textDocument/formatting to the oxfmt language server and applies the
--- returned edits to the in-memory buffer (no CLI spawn).
--- @param opts { bufnr: integer, on_done: fun(ok: boolean, err?: string) }
--- @return nil
function M.run(opts)
  local bufnr = opts.bufnr
  local oxfmt = vim.lsp.get_clients({ name = 'oxfmt', bufnr = bufnr })[1]
  if not oxfmt then
    return opts.on_done(false, 'oxfmt client missing')
  end

  -- make_formatting_params reads tabSize/insertSpaces from the current buffer,
  -- which is not necessarily the target buffer (run_all formats in background)
  local params = vim.api.nvim_buf_call(bufnr, vim.lsp.util.make_formatting_params)
  params.textDocument = { uri = vim.uri_from_bufnr(bufnr) }
  local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)

  oxfmt:request('textDocument/formatting', params, function(err, result)
    if err then
      return opts.on_done(false, err.message)
    end

    -- The edits carry no document version: applied after an edit made while the
    -- request was in flight (e.g. typing on after <A-s> in insert mode), they would
    -- land at shifted positions and corrupt the text, so discard them instead
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
