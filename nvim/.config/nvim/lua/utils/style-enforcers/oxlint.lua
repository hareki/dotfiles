local engine = require('utils.style-enforcers.engine')

--- @class utils.style-enforcers.oxlint
local M = {}

--- Run oxc.fixAll on a buffer through the oxlint language server
--- @param opts { bufnr: integer, client: vim.lsp.Client, on_done: fun(ok: boolean, err?: string) }
--- @return nil
function M.run(opts)
  local bufnr = opts.bufnr

  -- HACK: oxc.fixAll lints the file on disk and returns an unversioned edit, so with the formatted
  -- buffer unsaved the fix lands at wrong positions, corrupting the file; flush it to disk first
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
