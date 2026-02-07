---@class plugins.ui.nvim-ufo.utils
local M = {}

local ui = require('utils.ui')

---Custom fold virtual text handler for nvim-ufo
---Displays a folded region with dynamic truncation and a pill-shaped line count indicator.
---Source: `https://github.com/kevinhwang91/nvim-ufo?tab=readme-ov-file#customize-fold-text`
---@param virt_text table Array of virtual text chunks (text, hl_group pairs)
---@param lnum integer Starting line number of the fold
---@param end_lnum integer Ending line number of the fold
---@param width integer Available width for virtual text
---@param truncate function Function to truncate text to a given width
---@return table[] new_virt_text Modified virtual text chunks
function M.fold_text_handler(virt_text, lnum, end_lnum, width, truncate)
  local virt_text_result = {}
  local cur_width = 0
  local suffix_content = ('%s %d'):format(Icons.actions.fold, end_lnum - lnum)
  local target_width = width - ui.pill_display_width(suffix_content)

  for _, chunk in ipairs(virt_text) do
    local chunk_text = chunk[1]
    local chunk_width = vim.fn.strdisplaywidth(chunk_text)

    if target_width > cur_width + chunk_width then
      table.insert(virt_text_result, chunk)
    else
      chunk_text = truncate(chunk_text, target_width - cur_width)
      chunk_width = vim.fn.strdisplaywidth(chunk_text)

      local hl_group = chunk[2]
      table.insert(virt_text_result, { chunk_text, hl_group })

      -- str width returned from truncate() may less than 2nd argument, need padding
      if cur_width + chunk_width < target_width then
        local padding = (' '):rep(target_width - cur_width - chunk_width)
        table.insert(virt_text_result, { padding })
      end

      break
    end

    cur_width = cur_width + chunk_width
  end

  vim.list_extend(virt_text_result, ui.pill_virt_text(suffix_content, 'UfoFoldPillInner', 'UfoFoldPillOuter'))

  return virt_text_result
end

return M
