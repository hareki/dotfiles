--- @class config.lazy.utils
local M = {}

--- Ensure lazy.nvim is installed, cloning from git if necessary
--- Adds lazy.nvim to the runtimepath after ensuring installation.
--- @return nil
function M.ensure_lazy()
  local lazypath = vim.fs.joinpath(vim.fn.stdpath('data'), 'lazy', 'lazy.nvim')
  if not vim.uv.fs_stat(lazypath) then
    local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
    local out = vim
      .system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }, {
        text = true,
      })
      :wait()

    if out.code ~= 0 then
      error('Error cloning lazy.nvim:\n' .. (out.stderr or ''))
    end
  end

  vim.opt.rtp:prepend(lazypath)
end

return M
