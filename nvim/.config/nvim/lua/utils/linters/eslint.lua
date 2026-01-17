---@class utils.linters.eslint
local M = {}

---Run eslint auto-fix on a buffer via LSP
---Executes eslint.applyAllFixes command through the eslint language server.
---@param opts { bufnr: integer, on_done: fun(ok: boolean, err?: string) }
---@return nil
function M.run(opts)
  local bufnr = opts.bufnr
  local eslint = vim.lsp.get_clients({ name = 'eslint', bufnr = bufnr })[1]
  if not eslint then
    return opts.on_done(false, 'eslint client missing')
  end

  local params = {
    command = 'eslint.applyAllFixes',
    arguments = {
      {
        uri = vim.uri_from_bufnr(bufnr),
        version = vim.lsp.util.buf_versions[bufnr],
      },
    },
  }

  eslint:request('workspace/executeCommand', params, function(err)
    if err then
      return opts.on_done(false, err.message)
    end

    opts.on_done(true)
  end, bufnr)
end

return M
