--- @class core.snacks-nvim.pickers.layouts
local M = {}

--- @class core.snacks-nvim.pickers.layouts.Opts
--- @field width integer        Outer window width
--- @field height integer       Outer window height
--- @field preview_title string Title shown above the preview pane

--- The input + list column shared by every layout.
local function input_list_box()
  return {
    box = 'vertical',
    border = 'rounded',
    title = '{title} {live}',
    title_pos = 'center',
    { win = 'input', height = 1, border = 'bottom' },
    { win = 'list', border = 'none' },
  }
end

--- @param opts core.snacks-nvim.pickers.layouts.Opts
--- @param box 'horizontal' | 'vertical' Direction the list column and preview are arranged
--- @param preview table The preview window box (carries its own width/height split)
local function frame(opts, box, preview)
  return {
    cycle = true,
    layout = {
      backdrop = false,
      width = opts.width,
      max_width = opts.width,
      height = opts.height,
      max_height = opts.height,
      border = 'none',
      box = box,
      input_list_box(),
      preview,
    },
  }
end

--- Preview pane to the right of the list.
--- @param opts core.snacks-nvim.pickers.layouts.Opts
function M.preview_right(opts)
  return frame(opts, 'horizontal', {
    win = 'preview',
    title = opts.preview_title,
    width = 0.5,
    border = 'rounded',
  })
end

--- Preview pane below the list.
--- @param opts core.snacks-nvim.pickers.layouts.Opts
function M.preview_below(opts)
  return frame(opts, 'vertical', {
    win = 'preview',
    title = opts.preview_title,
    height = 0.5,
    border = 'rounded',
  })
end

return M
