--- @class config.lazy.utils
local M = {}

--- Clone lazy.nvim if it's missing and add it to the runtimepath
--- @return nil
function M.ensure_lazy()
  local lazypath = vim.fs.joinpath(vim.fn.stdpath('data'), 'lazy', 'lazy.nvim')
  if not vim.uv.fs_stat(lazypath) then
    -- The fork named by core/lazy-nvim.lua, on main: its patch lets that spec keep the url
    local lazyrepo = 'https://github.com/hareki/lazy.nvim.git'
    local out = vim
      .system({ 'git', 'clone', '--filter=blob:none', lazyrepo, lazypath }, {
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
