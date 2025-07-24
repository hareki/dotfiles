---@class configs.lazy.utils
local M = {}

function M.ensure_lazy()
  -- [[ Install `lazy.nvim` plugin manager ]]
  --    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
  local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
  if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
    local out =
      vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
      error('Error cloning lazy.nvim:\n' .. out)
    end
  end

  ---@type vim.Option
  local rtp = vim.opt.rtp
  rtp:prepend(lazypath)
end

function M.register_events()
  local Event = require('lazy.core.handler.event')
  Event.mappings.LazyFile =
    { id = 'LazyFile', event = { 'BufReadPost', 'BufNewFile', 'BufWritePre' } }
  Event.mappings['User LazyFile'] = Event.mappings.LazyFile
end

return M
