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

  local params = vim.lsp.util.make_formatting_params()
  params.textDocument = { uri = vim.uri_from_bufnr(bufnr) }

  oxfmt:request('textDocument/formatting', params, function(err, result)
    if err then
      return opts.on_done(false, err.message)
    end

    if result then
      vim.lsp.util.apply_text_edits(result, bufnr, oxfmt.offset_encoding)
    end

    opts.on_done(true)
  end, bufnr)
end

return M
