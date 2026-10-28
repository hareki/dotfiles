--- @class core.lsp.nvim-lspconfig.utils.diagnostic-range-fix
--- HACK: some servers end a diagnostic's range at column 0 of the next line, so line lookups
--- (eagle's popup) return it there too; end such ranges on their own line instead
local M = {}

--- End a diagnostic that stops at column 0 of the next line at its own line's end instead,
--- pulling a start past that end back onto the last character so it still underlines one
--- @param line string | false The line text for bounds checking, false when the line is gone
--- @param diagnostic vim.Diagnostic The diagnostic to fix in-place
--- @return nil
local function fix_diagnostic_range(line, diagnostic)
  if not line then
    return
  end

  local line_len = #line

  -- Only the vim-side range is rewritten: user_data.lsp goes back verbatim as code action context,
  -- and servers like eslint look fixes up by the exact (UTF-16) range they sent

  diagnostic.end_lnum = diagnostic.lnum

  -- Only shift backward if col is out of bounds (pointing past the line end)
  if diagnostic.col >= line_len then
    diagnostic.col = math.max(0, line_len - 1)
  end
  diagnostic.end_col = line_len
end

--- Fix all diagnostic ranges in a list
--- Fetches lines (once per unique lnum) only for diagnostics whose range needs fixing.
--- @param bufnr integer
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

      fix_diagnostic_range(line_cache[lnum], diagnostic)
    end
  end
end

return M
