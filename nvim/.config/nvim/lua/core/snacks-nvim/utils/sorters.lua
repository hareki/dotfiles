--- @class core.snacks.utils.sorters
local M = {}

--- Sort function for buffer picker (modified first, then by score/length/index)
--- @param a snacks.picker.Item First item to compare
--- @param b snacks.picker.Item Second item to compare
--- @return boolean less True if a should come before b
function M.buffer_sort(a, b)
  -- The matcher sorts from snacks' async loop, a fast event context where vim.bo raises
  -- E5560; the buffers finder's getbufinfo() snapshot is safe to read there
  local a_modified = a.info.changed == 1
  local b_modified = b.info.changed == 1

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
