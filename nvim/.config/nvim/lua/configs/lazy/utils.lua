---@class configs.lazy.utils
local M = {}

function M.ensure_lazy()
  -- [[ Install `lazy.nvim` plugin manager ]]
  --    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
  local lazypath = vim.fs.joinpath(vim.fn.stdpath('data'), 'lazy', 'lazy.nvim')
  if not vim.uv.fs_stat(lazypath) then
    local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
    local out = vim
      .system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }, {
        text = true,
      })
      :wait()
    if not out or out.code ~= 0 then
      error('Error cloning lazy.nvim:\n' .. (out and out.stderr or ''))
    end
  end

  vim.opt.rtp:prepend(lazypath)
end

return M
