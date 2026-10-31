-- Function-valued, so snacks sizes and centers the layouts per open, across terminal resizes
local lg = UI.layout.picker_fn('lg')

--- The input + list column beside a preview window, arranged along `box`
--- @param box 'horizontal' | 'vertical'
--- @param split { width?: number, height?: number } The preview's share of the frame
local function frame(box, split)
  return {
    cycle = true,
    layout = {
      backdrop = false,
      -- No max_width/max_height: snacks takes only numbers there, pinning these to stale sizes
      width = lg.width,
      height = lg.height,
      border = 'none',
      box = box,
      {
        box = 'vertical',
        border = 'rounded',
        title = '{title} {live}',
        { win = 'input', height = 1, border = 'bottom' },
        { win = 'list', border = 'none' },
      },
      {
        win = 'preview',
        title = Conf.picker.PREVIEW_TITLE,
        width = split.width,
        height = split.height,
        border = 'rounded',
      },
    },
  }
end

--- @class features.search.snacks.layouts
local M = {}

M.preview_right = frame('horizontal', { width = 0.5 })
M.preview_below = frame('vertical', { height = 0.5 })

return M
