local engine = require('utils.style-enforcers.engine')

--- @class utils.style-enforcers.oxlint
local M = {}

--- Run oxc.fixAll on a buffer through the oxlint language server
--- @param opts utils.style-enforcers.RunnerOpts
--- @return nil
function M.run(opts)
  local bufnr = opts.bufnr

  -- HACK: oxc.fixAll lints the file on disk and returns an unversioned edit, so with the formatted
  -- buffer unsaved the fix lands at wrong positions, corrupting the file; flush it to disk first
  local ok, err = engine.write(bufnr)
  if not ok then
    return opts.on_done(false, 'write before oxc.fixAll failed: ' .. tostring(err))
  end

  engine.execute_command(opts, 'oxc.fixAll', { uri = vim.uri_from_bufnr(bufnr) })
end

return M
