--- @class chrome.dropbar.utils
local M = {}

local IGNORED_FILETYPES = { help = true, trouble = true, ['grug-far'] = true }

--- Check if the buffer never gets a dropbar: an ignored filetype, or a terminal
--- @param buf integer
--- @return boolean
function M.is_ignored(buf)
  return IGNORED_FILETYPES[vim.bo[buf].filetype] == true or vim.bo[buf].buftype == 'terminal'
end

--- Filters out help files, terminals, and large files (>1MB).
--- @param buf integer
--- @param win integer
--- @param _ table | nil
--- @return boolean
function M.enable(buf, win, _)
  if
    not vim.api.nvim_buf_is_valid(buf)
    or not vim.api.nvim_win_is_valid(win)
    -- Floats stay bare unless Snacks flags one as a main window: its zen popup
    -- hosts a real buffer and earns a breadcrumb like any split
    or (vim.fn.win_gettype(win) ~= '' and not vim.w[win].snacks_main)
    or vim.wo[win].winbar ~= ''
    or M.is_ignored(buf)
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
--- @return table[] sources
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
