---@class util.buffer
local M = {}

--- Counts all opened file/regular/normal buffers
---
--- A buffer is considered a normal file buffer if:
--- 1. It is listed (`buflisted` is true).
--- 2. Its `buftype` is empty (`''`).
--- 3. It has a non-empty name (not a "No Name" buffer).
---
--- @return number The count of opened normal file buffers, excluding "No Name" buffers.
function M.count_file_buffers()
  local count = 0
  local bufs = vim.api.nvim_list_bufs()

  local buflisted = vim.fn.buflisted
  local get_option = vim.api.nvim_get_option_value
  local buf_get_name = vim.api.nvim_buf_get_name

  for _, bufnr in ipairs(bufs) do
    if buflisted(bufnr) == 1 then
      local buftype = get_option("buftype", { buf = bufnr })
      if buftype == "" then
        local bufname = buf_get_name(bufnr)
        if bufname ~= "" then
          count = count + 1
        end
      end
    end
  end

  return count
end

return M
