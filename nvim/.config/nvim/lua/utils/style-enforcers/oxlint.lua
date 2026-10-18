local engine = require('utils.style-enforcers.engine')

--- @class utils.style-enforcers.oxlint
local M = {}

--- Run oxlint auto-fix on a buffer via LSP
--- Executes oxc.fixAll command through the oxlint language server.
--- @param opts { bufnr: integer, client: vim.lsp.Client, on_done: fun(ok: boolean, err?: string) }
--- @return nil
function M.run(opts)
  local bufnr = opts.bufnr

  -- HACK: oxc.fixAll lints the file ON DISK (read_to_string), not the in-memory buffer,
  -- and returns an unversioned WorkspaceEdit that Neovim cannot reject as stale.
  -- The buffer has just been formatted in memory but not yet saved, so disk is one
  -- step behind and the fix lands at wrong positions, corrupting the file. Flush the
  -- formatted buffer to disk first so oxc fixes against matching content.
  local ok, err = engine.write(bufnr)
  if not ok then
    return opts.on_done(false, 'write before oxc.fixAll failed: ' .. tostring(err))
  end

  local params = {
    command = 'oxc.fixAll',
    arguments = {
      {
        uri = vim.uri_from_bufnr(bufnr),
      },
    },
  }

  opts.client:request('workspace/executeCommand', params, function(err)
    opts.on_done(not err, err and err.message)
  end, bufnr)
end

return M
