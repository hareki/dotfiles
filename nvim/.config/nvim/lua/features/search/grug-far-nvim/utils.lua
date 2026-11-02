--- @class features.search.grug-far.utils
local M = {}

-- grug-far passes previewWindow straight to nvim_open_win, so geometry must be plain numbers,
-- computed per open; the static opts only cover direct :GrugFar invocations
--- @return { window_creation_command: string, preview_window: table }
function M.preview_geometry()
  return {
    window_creation_command = UI.layout.side_panel_width('md') .. 'vsplit',
    preview_window = UI.layout.side_preview(),
  }
end

return M
