local engine = require('utils.style-enforcers.engine')

--- @class utils.style-enforcers.oxlint
local M = {}

--- Run oxc.fixAll on a buffer through the oxlint language server
--- @param opts utils.style-enforcers.RunnerOpts
--- @return nil
function M.run(opts)
  local bufnr = opts.bufnr
  local document = { uri = vim.uri_from_bufnr(bufnr) }
  local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)

  -- oxc.fixAll replays the fixes of the server's last lint as an unversioned edit, and the format
  -- step's didChange doesn't re-lint (a diagnostic pull or a save does), so stale fixes would land
  -- at wrong positions and corrupt the text: pull first to re-lint the buffer as it is
  opts.client:request('textDocument/diagnostic', { textDocument = document }, function(err)
    if err then
      return opts.on_done(false, err.message)
    end

    -- An edit made while the lint ran shifts the fix positions again, as in oxfmt.lua
    if
      not vim.api.nvim_buf_is_valid(bufnr)
      or vim.api.nvim_buf_get_changedtick(bufnr) ~= changedtick
    then
      return opts.on_done(false, engine.BUFFER_CHANGED)
    end

    engine.execute_command(opts, 'oxc.fixAll', document)
  end, bufnr)
end

return M
