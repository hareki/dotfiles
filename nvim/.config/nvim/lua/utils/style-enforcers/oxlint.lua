local engine = require('utils.style-enforcers.engine')

--- @class utils.style-enforcers.oxlint
local M = {}

--- Run oxc.fixAll on a buffer through the oxlint language server
--- @param opts utils.style-enforcers.engine.RunnerOpts
--- @return nil
function M.run(opts)
  local document = vim.lsp.util.make_text_document_params(opts.bufnr)

  -- oxc.fixAll replays the server's last lint as an unversioned edit, and the format step's
  -- didChange doesn't re-lint, so pull diagnostics first or stale fixes would corrupt the text
  engine.request(opts, 'textDocument/diagnostic', { textDocument = document }, function()
    engine.execute_command(opts, 'oxc.fixAll', document)
  end)
end

return M
