local engine = require('utils.style-enforcers.engine')

--- @class utils.style-enforcers.oxlint
local M = {}

--- Run oxc.fixAll on a buffer through the oxlint language server
--- @param opts utils.style-enforcers.engine.RunnerOpts
--- @return nil
function M.run(opts)
  local document = vim.lsp.util.make_text_document_params(opts.bufnr)

  -- oxc.fixAll replays the fixes of the server's last lint as an unversioned edit, and the format
  -- step's didChange doesn't re-lint (a diagnostic pull or a save does), so stale fixes would land
  -- at wrong positions and corrupt the text: pull first to re-lint the buffer as it is
  engine.request(opts, 'textDocument/diagnostic', { textDocument = document }, function()
    engine.execute_command(opts, 'oxc.fixAll', document)
  end)
end

return M
