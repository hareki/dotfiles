--- @class core.lsp.nvim-lspconfig.utils.diagnostic-range-fix
--- HACK: Some servers emit zero-width or out-of-bounds diagnostics whose end_col is 0
--- and end_lnum is start_lnum+1, which makes them invisible. This module rewrites
--- those ranges so they underline at least one character on the original line.
local M = {}

--- Fix zero-width or out-of-bounds diagnostics to underline at least one character
--- Corrects diagnostics that would otherwise be invisible due to invalid ranges.
--- Expects a diagnostic whose range ends at column 0 of the next line (see M.apply).
--- @param line string | nil The line text for bounds checking
--- @param diagnostic vim.Diagnostic The diagnostic to fix in-place
--- @return nil
local function fix_diagnostic_range(line, diagnostic)
  if not line then
    return
  end

  local line_len = #line

  -- Only the vim-side range is rewritten. user_data.lsp is echoed back verbatim as
  -- code action context, and servers like eslint look their fixes up by the exact
  -- range they sent (its characters are also UTF-16 offsets, not byte columns)

  -- Set end line to start line
  diagnostic.end_lnum = diagnostic.lnum

  -- Only shift backward if col is out of bounds (pointing past the line end)
  if diagnostic.col >= line_len then
    diagnostic.col = math.max(0, line_len - 1)
  end
  diagnostic.end_col = math.min(diagnostic.col + 1, line_len)
end

--- Fix all diagnostic ranges in a list
--- Fetches lines (once per unique lnum) only for diagnostics whose range needs fixing.
--- @param bufnr integer Buffer number
--- @param diagnostics vim.Diagnostic[] List of diagnostics to fix in-place
--- @return nil
function M.apply(bufnr, diagnostics)
  local line_cache = {}
  for _, diagnostic in ipairs(diagnostics) do
    -- Only ranges ending at column 0 of the next line are fixed, so most
    -- diagnostics never need their line text
    local lnum = diagnostic.lnum
    if diagnostic.end_col == 0 and diagnostic.end_lnum == lnum + 1 then
      if line_cache[lnum] == nil then
        local lines = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)
        line_cache[lnum] = lines[1] or false -- false = no line found
      end

      fix_diagnostic_range(line_cache[lnum] or nil, diagnostic)
    end
  end
end

return M
