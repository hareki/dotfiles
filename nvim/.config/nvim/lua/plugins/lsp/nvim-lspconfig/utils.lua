local M = {}

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

---@param bufnr integer Buffer number
---@param diagnostics vim.Diagnostic[]
function M.fix_all_diagnostic_ranges(bufnr, diagnostics)
  for _, diagnostic in ipairs(diagnostics) do
    M.fix_diagnostic_range(bufnr, diagnostic)
  end
end

---@param diagnostic vim.Diagnostic
local function get_pos_key(diagnostic)
  return string.format(
    '%d:%d-%d:%d',
    diagnostic.lnum or -1,
    diagnostic.col or -1,
    diagnostic.end_lnum or -1,
    diagnostic.end_col or -1
  )
end

---@param diagnostic vim.Diagnostic
---@return vim.Diagnostic?
local function create_underline_diagnostic(diagnostic)
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

-- HACK: Intercept vim.diagnostic.set to apply both unnecessary and severity-based styling (if severity < HINT)
---@param diagnostics vim.Diagnostic[]
function M.apply_underline_hack(diagnostics)
  -- Group diagnostics by position to check if underline would already be present
  local positions = {}
  for _, diagnostic in ipairs(diagnostics) do
    local key = get_pos_key(diagnostic)
    positions[key] = positions[key] or {}
    table.insert(positions[key], diagnostic)
  end

  -- Create duplicates for unnecessary diagnostics to get both styling effects
  local underline_hacks = {}
  for _, diagnostic in ipairs(diagnostics) do
    local has_unnecessary = diagnostic._tags and diagnostic._tags.unnecessary

    if has_unnecessary then
      local key = get_pos_key(diagnostic)
      local position_diagnostics = positions[key]

      local has_underline = false
      -- Check if there's already a diagnostic at this exact position with same/higher severity without unnecessary tag
      for _, other in ipairs(position_diagnostics) do
        local other_has_unnecessary = other._tags and other._tags.unnecessary
        if not other_has_unnecessary and other.severity <= diagnostic.severity then
          has_underline = true
          break
        end
      end

      -- Only duplicate if no underline would be present otherwise
      if not has_underline then
        local dup = create_underline_diagnostic(diagnostic)
        if dup then
          table.insert(underline_hacks, dup)
        end
      end
    end
  end

  -- Append to get both styling effects
  vim.list_extend(diagnostics, underline_hacks)
end

function M.load_lsp_configs()
  local lsp_config_path = vim.fn.stdpath('config') .. '/lua/plugins/lsp/nvim-lspconfig/lsp'
  for name, file_type in vim.fs.dir(lsp_config_path) do
    if file_type == 'file' and name:match('%.lua$') then
      local server_name = name:gsub('%.lua$', '')
      local config = require('plugins.lsp.nvim-lspconfig.lsp.' .. server_name)

      local opts = config.opts
      if type(opts) == 'function' then
        opts = opts()
      end

      -- Configure the LSP server
      vim.lsp.config(server_name, opts)

      -- Run setup if provided
      if config.setup then
        config.setup()
      end
    end
  end
end

return M
