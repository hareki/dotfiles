---@class util.buffer
local M = {}

--- Counts all opened file/regular/normal buffers.
---
--- A buffer is considered a normal file buffer if:
--- 1. It is listed (`buflisted` is true).
--- 2. Its `buftype` is empty (`''`).
---
--- @return number The count of opened normal file buffers.
function M.count_file_buffers()
  local count = 0
  local bufs = vim.api.nvim_list_bufs()

  local buflisted = vim.fn.buflisted
  local get_option = vim.api.nvim_get_option_value

  for _, bufnr in ipairs(bufs) do
    -- buffer is listed
    if buflisted(bufnr) == 1 then
      -- buffer is file
      local buftype = get_option("buftype", { buf = bufnr })
      if buftype == "" then
        count = count + 1
      end
    end
  end

  return count
end

--- Closes all opened file/regular/normal buffers.
---
--- A buffer is considered a normal file buffer if:
--- 1. It is listed (`buflisted` is true).
--- 2. Its `buftype` is empty (`''`).
---
--- @param current boolean If `true`, closes the current buffer as well. If `false`, keeps the current buffer open.
--- @return nil
function M.close_file_buffers(current)
  local bufs = vim.api.nvim_list_bufs()
  local current_bufnr = vim.api.nvim_get_current_buf()

  for _, bufnr in ipairs(bufs) do
    local is_listed = vim.fn.buflisted(bufnr) == 1
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
    local is_normal_file = buftype == ""

    if is_listed and is_normal_file then
      if current then
        vim.api.nvim_buf_delete(bufnr, { force = false })
      else
        if bufnr ~= current_bufnr then
          vim.api.nvim_buf_delete(bufnr, { force = false })
        end
      end
    end
  end
end

return M
