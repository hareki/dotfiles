--- @class utils.style-enforcers.oxlint
local M = {}

--- Run oxlint auto-fix on a buffer via LSP
--- Executes oxc.fixAll command through the oxlint language server.
--- @param opts { bufnr: integer, on_done: fun(ok: boolean, err?: string) }
--- @return nil
function M.run(opts)
  local bufnr = opts.bufnr
  local oxlint = vim.lsp.get_clients({ name = 'oxlint', bufnr = bufnr })[1]
  if not oxlint then
    return opts.on_done(false, 'oxlint client missing')
  end

  -- HACK: oxc.fixAll lints the file ON DISK (read_to_string), not the in-memory buffer,
  -- and returns an unversioned WorkspaceEdit that Neovim cannot reject as stale.
  -- The buffer has just been formatted in memory but not yet saved, so disk is one
  -- step behind and the fix lands at wrong positions, corrupting the file. Flush the
  -- formatted buffer to disk first so oxc fixes against matching content.
  -- pcall: this runner can execute inside the previous enforcer's LSP response
  -- callback, outside the pipeline's pcall; an unwritable buffer (E45 readonly,
  -- E212 missing dir) would otherwise escape and leak the buffer lock
  if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].modified then
    local ok, err = pcall(vim.api.nvim_buf_call, bufnr, function()
      vim.cmd.write()
    end)
    if not ok then
      return opts.on_done(false, 'write before oxc.fixAll failed: ' .. tostring(err))
    end
  end

  local params = {
    command = 'oxc.fixAll',
    arguments = {
      {
        uri = vim.uri_from_bufnr(bufnr),
      },
    },
  }

  oxlint:request('workspace/executeCommand', params, function(err)
    if err then
      return opts.on_done(false, err.message)
    end

    opts.on_done(true)
  end, bufnr)
end

return M
