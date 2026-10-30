--- @class features.search.nvim-hlslens.utils
local M = {}

--- Execute search navigation (n/N) with hlslens integration
--- @param direction 'n' | 'N'
--- @return nil
function M.navigate(direction)
  local ok = pcall(function()
    local hlslens = require('hlslens')

    vim.cmd.normal({ args = { vim.v.count1 .. direction }, bang = true })
    hlslens.start()
  end)

  if not ok then
    local search_text = vim.fn.getreg('/')
    Notifier.warn(string.format('`%s` is not found', search_text), {
      title = 'nvim-hlslens',
    })
  end
end

--- Lens with direction arrows and a pill-shaped match position, adapted from
--- https://github.com/kevinhwang91/nvim-hlslens?tab=readme-ov-file#customize-virtual-text
--- @param render table Inner hlslens module, use `render.setVirt()` to set virtual text
--- @param position_list table (1,1)-indexed position list of search matches
--- @param nearest boolean Whether this is the nearest lens to cursor
--- @param index number Index of current match in pos_list
--- @param relative_index number Relative index from current position (negative = before, positive = after)
function M.search_text_handler(render, position_list, nearest, index, relative_index)
  local abs_relative_index = math.abs(relative_index)
  local text, chunks

  local indicator = ''
  if relative_index ~= 0 then
    local search_forward = vim.v.searchforward == 1
    indicator = search_forward ~= (relative_index > 0) and Conf.icons.navigation.UP
      or Conf.icons.navigation.DOWN
    if abs_relative_index > 1 then
      indicator = string.format('%d%s', abs_relative_index, indicator)
    end
  end

  local line_number, column = unpack(position_list[index])
  if nearest then
    local count = #position_list
    if indicator ~= '' then
      text = string.format('%s%s %d/%d', Conf.icons.actions.SEARCH, indicator, index, count)
    else
      text = string.format('%s%d/%d', Conf.icons.actions.SEARCH, index, count)
    end
    chunks = UI.pill.virt_text(text, 'HlSearchLensPillNearInner', 'HlSearchLensPillNearOuter')
  else
    text = string.format('%s %d', indicator, index)
    chunks = UI.pill.virt_text(text, 'HlSearchLensPillInner', 'HlSearchLensPillOuter')
  end

  render.setVirt(0, line_number - 1, column - 1, chunks, nearest)
end

return M
