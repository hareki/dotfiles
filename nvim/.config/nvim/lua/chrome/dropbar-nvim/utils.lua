--- @class chrome.dropbar.utils
local M = {}

local IGNORED_FILETYPES = { help = true, trouble = true, ['grug-far'] = true }
local IGNORED_BUFTYPES = { terminal = true }

--- Check if buffer has an ignored filetype
--- @param buf integer Buffer number
--- @return boolean
function M.is_ignored_filetype(buf)
  return IGNORED_FILETYPES[vim.bo[buf].filetype] == true
end

--- Check if buffer has an ignored buftype
--- @param buf integer Buffer number
--- @return boolean
function M.is_ignored_buftype(buf)
  return IGNORED_BUFTYPES[vim.bo[buf].buftype] == true
end

--- Determine if dropbar should be enabled for a buffer/window
--- Filters out help files, terminals, and large files (>1MB).
--- @param buf integer Buffer number
--- @param win integer Window handle
--- @param _ table | nil Additional info (unused)
--- @return boolean enabled True if dropbar should be enabled
function M.enable(buf, win, _)
  buf = (buf == 0 or buf == nil) and vim.api.nvim_get_current_buf() or buf
  if
    not vim.api.nvim_buf_is_valid(buf)
    or not vim.api.nvim_win_is_valid(win)
    -- Floats stay bare unless Snacks flags one as a main window: its zen popup
    -- hosts a real buffer and earns a breadcrumb like any split
    or (vim.fn.win_gettype(win) ~= '' and not vim.w[win].snacks_main)
    or vim.wo[win].winbar ~= ''
    or M.is_ignored_filetype(buf)
    or M.is_ignored_buftype(buf)
  then
    return false
  end

  local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
  if stat and stat.size > 1024 * 1024 then
    return false
  end

  return true
end

--- Build a dropbar source that renders a single static title symbol
--- @param opts { icon: string, icon_hl: string, name: string, name_hl: string }
--- @return table[] sources Dropbar sources list containing one static symbol
function M.title_symbol(opts)
  return {
    {
      get_symbols = function()
        local dropbar_bar = require('dropbar.bar')
        return {
          dropbar_bar.dropbar_symbol_t:new(opts),
        }
      end,
    },
  }
end

return M
