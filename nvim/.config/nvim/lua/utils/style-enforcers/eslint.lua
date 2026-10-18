--- @class utils.style-enforcers.eslint
local M = {}

--- Run eslint auto-fix on a buffer via LSP
--- Executes eslint.applyAllFixes command through the eslint language server.
--- @param opts { bufnr: integer, client: vim.lsp.Client, on_done: fun(ok: boolean, err?: string) }
--- @return nil
function M.run(opts)
  local bufnr = opts.bufnr
  local params = {
    command = 'eslint.applyAllFixes',
    arguments = {
      {
        uri = vim.uri_from_bufnr(bufnr),
        version = vim.lsp.util.buf_versions[bufnr],
      },
    },
  }

  opts.client:request('workspace/executeCommand', params, function(err)
    opts.on_done(not err, err and err.message)
  end, bufnr)
end

return M
