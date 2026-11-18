local keymap = require('utils.keymap')

--- @class features.editing.markdown-defaults.utils
local M = {}

-- Headings as matched by the runtime ftplugin's section jumps
local MARKDOWN_HEADING = [[\%(^#\{1,5\}\s\+\S\|^\S.*\n^[=-]\+$\)]]

-- Holds each buffer's wait for a real window
local wrap_group = vim.api.nvim_create_augroup(
  'features.editing.markdown-defaults.wrap-in-real-window',
  { clear = true }
)

--- @return true? done Also deletes the BufWinEnter autocmd apply() adds
local function wrap_in_real_window()
  if vim.fn.win_gettype() ~= 'autocmd' then
    -- Local only: vim.wo also sets the global value that later buffers and splits inherit
    vim.opt_local.wrap = true
    return true
  end
end

--- Wrap a markdown buffer's lines and add its visual-mode section jumps; runs on its FileType
--- @param buf integer
--- @return nil
function M.apply(buf)
  -- The ftplugin's visual-mode section jumps, disabled by g.no_markdown_maps (init.lua)
  local map = keymap.buf_mapper(buf)
  map(
    'x',
    ']]',
    string.format("<cmd>call search('%s', 'sW')<cr>", MARKDOWN_HEADING),
    'Jump to Next Section'
  )
  map(
    'x',
    '[[',
    string.format("<cmd>call search('%s', 'bsW')<cr>", MARKDOWN_HEADING),
    'Jump to Previous Section'
  )

  if wrap_in_real_window() then
    return
  end

  -- A hidden bufload() fires FileType and BufWinEnter in the autocmd window: wait for a real one
  vim.api.nvim_clear_autocmds({ group = wrap_group, buf = buf })
  vim.api.nvim_create_autocmd('BufWinEnter', {
    group = wrap_group,
    buf = buf,
    callback = wrap_in_real_window,
  })
end

return M
