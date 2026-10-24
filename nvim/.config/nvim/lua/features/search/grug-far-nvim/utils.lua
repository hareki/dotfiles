--- @class features.search.grug-far.utils
local M = {}

-- grug-far passes previewWindow straight to nvim_open_win, so geometry must be plain numbers,
-- computed per open; the static opts only cover direct :GrugFar invocations
--- @return { window_creation_command: string, preview_window: table }
function M.preview_geometry()
  local preview = UI.layout.side_preview()
  local panel_cols = UI.layout.side_size('side_panel', 'md')

  return {
    window_creation_command = panel_cols .. 'vsplit',
    preview_window = {
      row = preview.row,
      col = preview.col,
      title = Conf.picker.PREVIEW_TITLE,
      title_pos = 'center',
      width = preview.width,
      height = preview.height,
    },
  }
end

return M
