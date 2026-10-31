--- @class core.lsp.nvim-lspconfig.utils.diagnostic-range-fix
--- HACK: some servers end a diagnostic's range at column 0 of the next line, so line lookups
--- (eagle's popup) return it there too; end such ranges on their own line instead
local M = {}

--- End the range on its own line, pulling a start past that end back so it still underlines one
--- @param line string | false The line text for bounds checking, false when the line is gone
--- @param diagnostic vim.Diagnostic Fixed in place
--- @return nil
local function fix_diagnostic_range(line, diagnostic)
  if not line then
    return
  end

  local line_len = #line

  -- Only the vim-side range is rewritten: user_data.lsp goes back verbatim as code action context,
  -- and servers like eslint look fixes up by the exact (UTF-16) range they sent

  diagnostic.end_lnum = diagnostic.lnum

  if diagnostic.col >= line_len then
    diagnostic.col = math.max(0, line_len - 1)
  end
  diagnostic.end_col = line_len
end

--- @param bufnr integer
--- @param diagnostics vim.Diagnostic[] Fixed in place
--- @return nil
local function apply(bufnr, diagnostics)
  local line_cache = {}
  for _, diagnostic in ipairs(diagnostics) do
    -- Only column-0 ends are fixed, so most diagnostics never need their line text
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

--- Pass every diagnostic set from here on through the range fix
--- @return nil
function M.setup()
  local original_set = vim.diagnostic.set
  --- @param namespace integer
  --- @param bufnr integer
  --- @param diagnostics vim.Diagnostic[]
  --- @param opts? vim.diagnostic.Opts
  --- @diagnostic disable-next-line: duplicate-set-field
  vim.diagnostic.set = function(namespace, bufnr, diagnostics, opts)
    apply(bufnr, diagnostics)
    return original_set(namespace, bufnr, diagnostics, opts)
  end
end

return M
