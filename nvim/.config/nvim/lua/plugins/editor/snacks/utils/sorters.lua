---@class plugins.editor.snacks.utils.sorters
local M = {}

---Sort function for buffer picker (modified first, then by score/length/index)
---@param a snacks.picker.Item First item to compare
---@param b snacks.picker.Item Second item to compare
---@return boolean less True if a should come before b
function M.buffer_sort(a, b)
  -- Safely get modified state with pcall to handle fast event context
  local function get_modified(bufnr)
    if not bufnr then
      return false
    end
    local ok, modified = pcall(vim.api.nvim_get_option_value, 'modified', { buf = bufnr })
    return ok and modified or false
  end

  local a_bufnr = a.buf or a.bufnr or (a.item and a.item.bufnr)
  local b_bufnr = b.buf or b.bufnr or (b.item and b.item.bufnr)
  local a_modified = get_modified(a_bufnr)
  local b_modified = get_modified(b_bufnr)

  -- Modified buffers first
  if a_modified ~= b_modified then
    return a_modified
  end

  -- Then by score (descending)
  if a.score ~= b.score then
    return a.score > b.score
  end

  -- Then by text length (shorter first)
  local a_len = #(a.text or '')
  local b_len = #(b.text or '')
  if a_len ~= b_len then
    return a_len < b_len
  end

  -- Finally by index
  return (a.idx or 0) < (b.idx or 0)
end

return M
