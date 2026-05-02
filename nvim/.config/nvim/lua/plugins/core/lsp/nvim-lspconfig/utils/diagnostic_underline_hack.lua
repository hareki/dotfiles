---@class plugins.core.lsp.nvim-lspconfig.utils.diagnostic_underline_hack
---HACK: Diagnostics tagged "unnecessary" render with the faded DiagnosticUnnecessary
---highlight, which suppresses the severity-based underline. To get *both* effects,
---we duplicate the unnecessary diagnostic with the original severity but no tag —
---unless an equivalent severity-only diagnostic already covers that exact range.
local M = {}

---@param diagnostic vim.Diagnostic
local function get_pos_key(diagnostic)
  -- Use concat instead of string.format for LuaJIT performance
  return (diagnostic.lnum or -1)
    .. ':'
    .. (diagnostic.col or -1)
    .. '-'
    .. (diagnostic.end_lnum or -1)
    .. ':'
    .. (diagnostic.end_col or -1)
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

  -- Shallow copy only the fields needed for underline display (avoids expensive vim.deepcopy
  -- which would recursively copy user_data containing the full LSP response)
  return {
    lnum = diagnostic.lnum,
    end_lnum = diagnostic.end_lnum,
    col = diagnostic.col,
    end_col = diagnostic.end_col,
    severity = diagnostic.severity,
    source = 'underline-hack',
    message = '',
  }
end

---HACK: Must be called from inside a vim.diagnostic.set override — mutates the
---diagnostics list before it reaches the original set(), injecting tag-free copies
---so the severity underline fires alongside DiagnosticUnnecessary fading.
---@param diagnostics vim.Diagnostic[] List of diagnostics to process (modified in-place)
---@return nil
function M.apply(diagnostics)
  -- Fast path: skip entirely if no diagnostics have the unnecessary tag
  local has_any_unnecessary = false
  for _, d in ipairs(diagnostics) do
    if d._tags and d._tags.unnecessary then
      has_any_unnecessary = true
      break
    end
  end
  if not has_any_unnecessary then
    return
  end

  -- Group diagnostics by position to check if underline would already be present
  local positions = {}
  for _, diagnostic in ipairs(diagnostics) do
    local key = get_pos_key(diagnostic)
    if not positions[key] then
      positions[key] = {}
    end
    positions[key][#positions[key] + 1] = diagnostic
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
          underline_hacks[#underline_hacks + 1] = dup
        end
      end
    end
  end

  -- Append to get both styling effects
  if #underline_hacks > 0 then
    vim.list_extend(diagnostics, underline_hacks)
  end
end

return M
