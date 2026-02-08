---@class plugins.ui.nvim-hlslens.utils
local M = {}

local ui = require('utils.ui')

---Custom lens handler for nvim-hlslens search results
---Displays directional indicators (↑/↓) and pill-shaped position information for search matches.
---Source: `https://github.com/kevinhwang91/nvim-hlslens?tab=readme-ov-file#customize-virtual-text`
---@param render table Inner hlslens module, use `render.setVirt()` to set virtual text
---@param position_list table (1,1)-indexed position list of search matches
---@param nearest boolean Whether this is the nearest lens to cursor
---@param index number Index of current match in pos_list
---@param relative_index number Relative index from current position (negative = before, positive = after)
function M.search_text_handler(render, position_list, nearest, index, relative_index)
  local search_forward = vim.v.searchforward == 1
  local indicator, text, chunks
  local abs_relative_index = math.abs(relative_index)

  if abs_relative_index > 1 then
    indicator = ('%d%s'):format(
      abs_relative_index,
      search_forward ~= (relative_index > 1) and Icons.navigation.up or Icons.navigation.down
    )
  elseif abs_relative_index == 1 then
    indicator = search_forward ~= (relative_index == 1) and Icons.navigation.up
      or Icons.navigation.down
  else
    indicator = ''
  end

  local line_number, column = unpack(position_list[index])
  if nearest then
    local count = #position_list
    if indicator ~= '' then
      text = ('%s %d/%d'):format(indicator, index, count)
    else
      text = ('%d/%d'):format(index, count)
    end
    chunks = ui.pill_virt_text(text, 'HlSearchLensPillNearInner', 'HlSearchLensPillNearOuter')
  else
    text = ('%s %d'):format(indicator, index)
    chunks = ui.pill_virt_text(text, 'HlSearchLensPillInner', 'HlSearchLensPillOuter')
  end

  Snacks.words.disable()
  render.setVirt(0, line_number - 1, column - 1, chunks, nearest)
end

return M
