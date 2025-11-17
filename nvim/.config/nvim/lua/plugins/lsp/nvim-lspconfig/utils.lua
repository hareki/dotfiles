local M = {}

---@param diagnostic vim.Diagnostic
function M.get_pos_key(diagnostic)
  return string.format(
    '%d:%d-%d:%d',
    diagnostic.lnum,
    diagnostic.col,
    diagnostic.end_lnum,
    diagnostic.end_col
  )
end

---Fix zero-width or out-of-bounds diagnostics to underline at least one character
---@param bufnr integer Buffer number
---@param diagnostic vim.Diagnostic
function M.fix_diagnostic_range(bufnr, diagnostic)
  -- Get the line to check if col is out of bounds
  local line = vim.api.nvim_buf_get_lines(bufnr, diagnostic.lnum, diagnostic.lnum + 1, false)[1]
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

---@param diagnostic vim.Diagnostic
---@return vim.Diagnostic?
function M.create_underline_hack(diagnostic)
  local has_unnecessary = diagnostic._tags and diagnostic._tags.unnecessary
  if not has_unnecessary then
    return nil
  end

  if diagnostic.severity >= vim.diagnostic.severity.HINT then
    return nil
  end

  local dup = vim.deepcopy(diagnostic)
  dup._tags = nil
  dup.source = 'underline-hack'
  dup.code = nil
  dup.message = ''
  dup.user_data = nil

  return dup
end

return M
