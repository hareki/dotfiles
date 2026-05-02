---@class plugins.core.lsp.nvim-lspconfig.utils.diagnostic_range_fix
---HACK: Some servers emit zero-width or out-of-bounds diagnostics whose end_col is 0
---and end_lnum is start_lnum+1, which makes them invisible. This module rewrites
---those ranges so they underline at least one character on the original line.
local M = {}

---Fix zero-width or out-of-bounds diagnostics to underline at least one character
---Corrects diagnostics that would otherwise be invisible due to invalid ranges.
---@param line string|nil The line text for bounds checking
---@param diagnostic vim.Diagnostic The diagnostic to fix in-place
---@return nil
local function fix_diagnostic_range(line, diagnostic)
  if not line then
    return
  end

  local line_len = #line

  ---@class RangeValues
  ---@field start_col integer
  ---@field end_col integer
  ---@field start_line integer
  ---@field end_line integer

  ---Apply range fix using provided values
  ---@param range RangeValues
  ---@return RangeValues? fixed Fixed range values, or nil if no fix was needed
  local function fix_range(range)
    -- Check if range needs fixing (end_col is 0 and points to next line)
    if not (range.end_col == 0 and range.end_line == (range.start_line + 1)) then
      return nil
    end

    -- Set end line to start line
    range.end_line = range.start_line

    -- Only shift backward if col is out of bounds (pointing past the line end)
    if range.start_col >= line_len then
      range.start_col = math.max(0, line_len - 1)
    end
    range.end_col = math.min(range.start_col + 1, line_len)

    return range
  end

  local fixed = fix_range({
    start_col = diagnostic.col,
    end_col = diagnostic.end_col,
    start_line = diagnostic.lnum,
    end_line = diagnostic.end_lnum,
  })

  if fixed then
    diagnostic.col = fixed.start_col
    diagnostic.end_col = fixed.end_col
    diagnostic.lnum = fixed.start_line
    diagnostic.end_lnum = fixed.end_line
  end

  local lsp_range = diagnostic.user_data
    and diagnostic.user_data.lsp
    and diagnostic.user_data.lsp.range

  -- Fix LSP range if present
  if lsp_range then
    local lsp_fixed = fix_range({
      start_col = lsp_range['start'].character,
      end_col = lsp_range['end'].character,
      start_line = lsp_range['start'].line,
      end_line = lsp_range['end'].line,
    })

    if lsp_fixed then
      lsp_range['start'].character = lsp_fixed.start_col
      lsp_range['end'].character = lsp_fixed.end_col
      lsp_range['start'].line = lsp_fixed.start_line
      lsp_range['end'].line = lsp_fixed.end_line
    end
  end
end

---Fix all diagnostic ranges in a list
---Batch-fetches lines per unique lnum to avoid repeated nvim_buf_get_lines calls.
---@param bufnr integer Buffer number
---@param diagnostics vim.Diagnostic[] List of diagnostics to fix in-place
---@return nil
function M.apply(bufnr, diagnostics)
  -- Batch-fetch lines: collect unique lnums first
  local line_cache = {}
  for _, diagnostic in ipairs(diagnostics) do
    local lnum = diagnostic.lnum
    if line_cache[lnum] == nil then
      local lines = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)
      line_cache[lnum] = lines[1] or false -- false = no line found
    end
  end

  for _, diagnostic in ipairs(diagnostics) do
    local line = line_cache[diagnostic.lnum]
    fix_diagnostic_range(line or nil, diagnostic)
  end
end

return M
