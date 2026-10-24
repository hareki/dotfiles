--- @class chrome.modicator.utils
local M = {}

--- Patch modicator ahead of its setup()
--- @param modicator table
--- @return nil
function M.patch(modicator)
  -- HACK: modicator maps whole mode() codes only, sending the rest (ic, Rv, cv, !, ...) to
  -- NormalMode; resolve through UI.mode so the line number matches lualine's mode pill
  --- @diagnostic disable-next-line: duplicate-set-field
  modicator.hl_name_from_mode = function(mode)
    return UI.mode.name(mode) .. 'Mode'
  end

  -- HACK: modicator re-sets CursorLineNr on every ModeChanged, redrawing every window; link only
  -- on a target change (same render while highlights.defaults/use_cursorline_background are unset)
  --- @diagnostic disable-next-line: duplicate-set-field
  modicator.set_cursor_line_highlight = function(hl_name)
    if vim.api.nvim_get_hl(0, { name = 'CursorLineNr' }).link ~= hl_name then
      vim.api.nvim_set_hl(0, 'CursorLineNr', { link = hl_name })
    end
  end
end

return M
