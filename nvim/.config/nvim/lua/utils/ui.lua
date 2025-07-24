---@class utils.ui
local M = {}

--- @param group string
--- @param style vim.api.keyset.highlight
M.highlight = function(group, style)
  vim.api.nvim_set_hl(0, group, style)
end

--- A table of custom highlight groups and their corresponding styles.
--- @param custom_highlights table<string, vim.api.keyset.highlight>
M.set_highlights = function(custom_highlights)
  for group, style in pairs(custom_highlights) do
    M.highlight(group, style)
  end
end

--- @param name? "frappe" | "latte" | "macchiato" | "mocha"
M.get_palette = function(name)
  return require('catppuccin.palettes').get_palette(name or 'mocha')
end

---@param size 'sm' | 'lg'
function M.telescope_layout_config(size)
  return {
    size = size, -- Hint to calculate the position
    height = function()
      return require('utils.size').popup_config(size, true).height
    end,
    width = function()
      return require('utils.size').popup_config(size, true).width
    end,
  }
end

return M
