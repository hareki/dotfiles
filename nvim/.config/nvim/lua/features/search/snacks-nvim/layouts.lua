-- Function-valued, so snacks sizes and centers the layouts per open, across terminal resizes
local lg = UI.layout.picker_fn('lg')

--- The input + list column shared by every layout.
local function input_list_box()
  return {
    box = 'vertical',
    border = 'rounded',
    title = '{title} {live}',
    { win = 'input', height = 1, border = 'bottom' },
    { win = 'list', border = 'none' },
  }
end

--- @param box 'horizontal' | 'vertical' Direction the list column and preview are arranged
--- @param preview table The preview window box (carries its own width/height split)
local function frame(box, preview)
  return {
    cycle = true,
    layout = {
      backdrop = false,
      -- No max_width/max_height: they cannot be function-valued in snacks and
      -- would pin resize-safe (callable) dimensions back to stale numbers
      width = lg.width,
      height = lg.height,
      border = 'none',
      box = box,
      input_list_box(),
      preview,
    },
  }
end

--- @class features.search.snacks.layouts
local M = {}

M.preview_right = frame('horizontal', {
  win = 'preview',
  title = Conf.picker.PREVIEW_TITLE,
  width = 0.5,
  border = 'rounded',
})

M.preview_below = frame('vertical', {
  win = 'preview',
  title = Conf.picker.PREVIEW_TITLE,
  height = 0.5,
  border = 'rounded',
})

return M
