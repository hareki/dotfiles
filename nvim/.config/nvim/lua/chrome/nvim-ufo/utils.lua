--- @class chrome.nvim-ufo.utils
local M = {}

--- Fold text with dynamic truncation and a pill-shaped line count, adapted from
--- https://github.com/kevinhwang91/nvim-ufo?tab=readme-ov-file#customize-fold-text
--- @param virt_text table Array of virtual text chunks (text, hl_group pairs)
--- @param lnum integer Starting line number of the fold
--- @param end_lnum integer Ending line number of the fold
--- @param width integer Available width for virtual text
--- @param truncate function Function to truncate text to a given width
--- @return table[] new_virt_text Modified virtual text chunks
function M.fold_text_handler(virt_text, lnum, end_lnum, width, truncate)
  local virt_text_result = {}
  local cur_width = 0
  local suffix_content = string.format('%s %d', Conf.icons.actions.FOLD, end_lnum - lnum)
  local target_width = width - UI.pill.display_width(suffix_content)

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

      -- truncate() can return a narrower string than requested, so pad it
      if cur_width + chunk_width < target_width then
        local padding = (' '):rep(target_width - cur_width - chunk_width)
        table.insert(virt_text_result, { padding })
      end

      break
    end

    cur_width = cur_width + chunk_width
  end

  vim.list_extend(
    virt_text_result,
    UI.pill.virt_text(suffix_content, 'UfoFoldPillInner', 'UfoFoldPillOuter')
  )

  return virt_text_result
end

--- ufo's post-render stale fold check reads every namespace's extmarks on each visible line before
--- it looks at whether the line holds a fold, which took ~5 ms per pause with nothing folded
--- @return nil
function M.skip_stale_scan_without_folds()
  local fold_buffer = require('ufo.model.foldbuffer')
  local open_stale_folds = fold_buffer.openStaleFoldsByRange

  function fold_buffer:openStaleFoldsByRange(...)
    if self.foldedLineCount == 0 then
      return false
    end

    return open_stale_folds(self, ...)
  end
end

return M
