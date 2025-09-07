---@class utils.buffer
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
      local buftype = get_option('buftype', { buf = bufnr })
      if buftype == '' then
        local bufname = buf_get_name(bufnr)
        if bufname ~= '' then
          count = count + 1
        end
      end
    end
  end

  return count
end

function M.lualine()
  local ignore_filetypes = {
    'NvimTree',
    'lazy',
    'mason',
    'TelescopePrompt',
    'TelescopeResults',
    'toggleterm',
    'Trouble',
    'help',
    'lspinfo',
    'checkhealth',
    '',
  }

  if vim.tbl_contains(ignore_filetypes, vim.bo.filetype) then
    return ''
  end

  local bufnr = 0
  local status = require('configs.icons').file_status
  local bo = vim.bo[bufnr]
  local name = vim.api.nvim_buf_get_name(bufnr) or ''

  local out = {}

  if name == '' then
    if status.unnamed ~= '' then
      out[#out + 1] = status.unnamed
    end
  else
    if bo.buftype == '' then
      local uv = vim.uv or vim.loop
      if not uv.fs_stat(name) and status.new ~= '' then
        out[#out + 1] = status.new
      end
    end
  end

  if (bo.readonly or not bo.modifiable) and status.readonly ~= '' then
    out[#out + 1] = status.readonly
  end

  if bo.modified and status.modified ~= '' then
    out[#out + 1] = status.modified
  end

  return table.concat(out)
end

return M
