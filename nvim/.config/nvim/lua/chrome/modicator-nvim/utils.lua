--- @class chrome.modicator.utils
local M = {}

--- Patch modicator ahead of its setup()
--- @param modicator table The `modicator` module
--- @return nil
function M.patch(modicator)
  -- HACK: Modicator's own map matches whole mode() codes only, sending every code it doesn't
  -- list (ic, Rv, cv, !, r, rm, ...) to NormalMode; resolve through UI.mode so the line
  -- number matches lualine's mode pill
  --- @diagnostic disable-next-line: duplicate-set-field
  modicator.hl_name_from_mode = function(mode)
    return UI.mode.name(mode) .. 'Mode'
  end

  -- HACK: Modicator re-sets CursorLineNr on every ModeChanged, and each nvim_set_hl redraws every
  -- window, though most mode changes keep the color (an operator's n => no => n round trip).
  -- Link instead, only when the target group changes. The link renders the same as modicator's
  -- copy, since its highlights.defaults and use_cursorline_background are left unset here
  --- @diagnostic disable-next-line: duplicate-set-field
  modicator.set_cursor_line_highlight = function(hl_name)
    if vim.api.nvim_get_hl(0, { name = 'CursorLineNr' }).link ~= hl_name then
      vim.api.nvim_set_hl(0, 'CursorLineNr', { link = hl_name })
    end
  end
end

return M
