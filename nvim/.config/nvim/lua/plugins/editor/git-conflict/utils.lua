---@class plugins.editor.git-conflict.utils
local M = {}

-- Maximum number of lines to search backward/forward for conflict markers
local CONFLICT_SEARCH_RANGE = 500

function M.in_diffview_tab()
  local tab_name = vim.t.tab_name
  if type(tab_name) ~= 'string' then
    return false
  end

  return tab_name:find('^diffview%-tab') ~= nil
end

--- Detect if cursor is currently inside a conflict block
---@return boolean in_conflict true if cursor is in a conflict block
---@return string|nil region 'current', 'incoming', 'ancestor', 'current_separator', 'ancestor_separator', 'separator', or 'incoming_separator'
function M.cursor_in_conflict()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1 -- Convert to 0-based

  -- Search backwards from cursor for conflict start (limit search range)
  local start_line = nil
  local search_start = math.max(0, line - CONFLICT_SEARCH_RANGE)

  for i = line, search_start, -1 do
    local line_text = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1] or ''
    if line_text:match('^<<<<<<<') then
      start_line = i
      break
    end

    -- Early exit if we hit another conflict end marker (but not the current line)
    if i ~= line and line_text:match('^>>>>>>>') then
      return false, nil
    end
  end

  if not start_line then
    return false, nil
  end

  -- From the start, find conflict markers (limit forward search)
  local middle_line = nil
  local ancestor_line = nil
  local end_line = nil
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local max_search = math.min(line_count - 1, start_line + CONFLICT_SEARCH_RANGE)

  for i = start_line + 1, max_search do
    local line_text = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1] or ''

    if not ancestor_line and line_text:match('^|||||||') then
      ancestor_line = i
    elseif not middle_line and line_text:match('^=======') then
      middle_line = i
    elseif line_text:match('^>>>>>>>') then
      end_line = i
      break
    end
  end

  -- Validate conflict block structure and cursor position
  if not end_line or not middle_line or line > end_line then
    return false, nil
  end

  -- Determine region (optimized branching)
  if line == start_line then
    return true, 'current_separator'
  elseif line == middle_line then
    return true, 'separator'
  elseif line == end_line then
    return true, 'incoming_separator'
  elseif ancestor_line then
    if line == ancestor_line then
      return true, 'ancestor_separator'
    elseif line < ancestor_line then
      return true, 'current'
    elseif line < middle_line then
      return true, 'ancestor'
    else
      return true, 'incoming'
    end
  else
    -- No ancestor (2-way merge)
    if line < middle_line then
      return true, 'current'
    else
      return true, 'incoming'
    end
  end
end

return M
