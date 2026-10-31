local engine = require('utils.style-enforcers.engine')

--- @class utils.style-enforcers.oxfmt
local M = {}

--- Format a buffer in memory with the oxfmt language server's edits (no CLI spawn)
--- @param opts utils.style-enforcers.engine.RunnerOpts
--- @return nil
function M.run(opts)
  local bufnr = opts.bufnr

  -- make_formatting_params reads the current buffer, and run_all formats in the background
  local params = vim.api.nvim_buf_call(bufnr, vim.lsp.util.make_formatting_params)

  engine.request(opts, 'textDocument/formatting', params, function(result)
    if result then
      vim.lsp.util.apply_text_edits(result, bufnr, opts.client.offset_encoding)
    end

    opts.on_done(true)
  end)
end

return M
