local M = {}

-- Chrome colors (headers, notes, --stat, commit metadata) mirror the delta
-- catppuccin-mocha theme from ~/.gitconfig. The four diff backgrounds are
-- placeholders overwritten by load_diff_colors() with the CodeDiff* groups so
-- lazygit shows exactly what codediff.nvim shows in the editor; syntax colors
-- come from catppuccin at runtime.
M.palette = {
  default_fg = 0xcdd6f4,
  decoration = 0x6c7086,
  minus_bg = 0x493447,
  minus_emph_bg = 0x694559,
  plus_bg = 0x394545,
  plus_emph_bg = 0x4e6356,
  minus_num = 0xf38ba8,
  plus_num = 0xa6e3a1,
  hunk_num = 0xa6adc8,
  commit_hash = 0xf9e2af,
  decorations_fg = 0x89b4fa,
  stat_count = 0xa6adc8,
  filler_fg = 0x444444,
}

--- Copy the diff backgrounds out of the CodeDiff* groups. Must run after
--- codediff.nvim's highlights.setup() has derived them from the colorscheme.
function M.load_diff_colors()
  local map = {
    minus_bg = "CodeDiffLineDelete",
    minus_emph_bg = "CodeDiffCharDelete",
    plus_bg = "CodeDiffLineInsert",
    plus_emph_bg = "CodeDiffCharInsert",
  }
  for key, group in pairs(map) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    if ok and hl and hl.bg then
      M.palette[key] = hl.bg
    end
  end
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = "CodeDiffFiller", link = false })
  if ok and hl and hl.fg then
    M.palette.filler_fg = hl.fg
  end
end

local cache = {}

local function lookup(group)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  if ok and hl and (hl.fg or hl.bold or hl.italic or hl.underline) then
    return { fg = hl.fg, bold = hl.bold, italic = hl.italic, underline = hl.underline }
  end
  return nil
end

--- Resolve a treesitter capture to highlight attrs the way nvim does:
--- @capture.lang, then the capture with dot-segments progressively stripped
--- (@function.call.lua => @function.call => @function). Returns nil when the
--- theme defines nothing (render with the default fg).
function M.attrs(capture, lang)
  local key = capture .. "\0" .. lang
  local hit = cache[key]
  if hit ~= nil then
    return hit or nil
  end

  local attrs = lookup("@" .. capture .. "." .. lang)
  local cap = capture
  while not attrs do
    attrs = lookup("@" .. cap)
    local stripped = cap:match("^(.*)%.[^.]+$")
    if not stripped then
      break
    end
    cap = stripped
  end

  cache[key] = attrs or false
  return attrs
end

return M
