local common = require('utils.common')

--- @class features.git.gitsigns.utils
local M = {}

--- Build a setup callback that wires <Esc>/<Tab> popup navigation for the given buffer.
--- Returns a function that, when invoked after a popup opens, attaches keymaps to
--- toggle focus between the source buffer and the popup window.
--- @param source_buffer integer The buffer the popup was launched from
--- @param popup_type string Gitsigns popup type ('blame' | 'hunk')
function M.build_popup_navigation(source_buffer, popup_type)
  return function()
    local popup = require('gitsigns.popup')
    local popup_win_id = popup.is_open(popup_type)

    if not popup_win_id then
      return
    end

    local popup_buf_id = vim.api.nvim_win_get_buf(popup_win_id)

    local function popup_map(mode, l, r, desc)
      vim.keymap.set(mode, l, r, { buffer = popup_buf_id, desc = desc })
    end

    local function close_popup()
      if vim.api.nvim_win_is_valid(popup_win_id) then
        vim.api.nvim_win_close(popup_win_id, true)
      end
    end

    local function focus_popup()
      local current_win_id = vim.api.nvim_get_current_win()

      if not vim.api.nvim_win_is_valid(popup_win_id) then
        return
      end

      popup_map('n', 'q', function()
        close_popup()
      end, 'Close Popup')

      popup_map('n', '<Esc>', function()
        close_popup()
      end, 'Close Popup')

      popup_map('n', '<Tab>', function()
        popup.ignore_cursor_moved = true
        common.focus_win(current_win_id)
      end, 'Focus Original Window')

      if current_win_id ~= popup_win_id then
        popup.focus_open(popup_type)
      end
    end

    local release_source_maps = common.override_buf_keymaps(source_buffer, {
      { 'n', '<Esc>', close_popup, { desc = 'Close Popup', silent = true } },
      { 'n', '<Tab>', focus_popup, { desc = 'Focus Popup Window', silent = true } },
    })

    vim.api.nvim_create_autocmd('WinClosed', {
      pattern = tostring(popup_win_id),
      once = true,
      callback = release_source_maps,
    })
  end
end

return M
