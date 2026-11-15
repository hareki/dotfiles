local M = {}

-- Chrome colors mirror ~/.gitconfig's delta catppuccin-mocha theme. load_diff_colors(), run by
-- bootstrap, fills them from catppuccin's palette and the diff colors from the CodeDiff* groups.
M.palette = {}

--- A highlight group's resolved attrs (empty when undefined), or nil for a name nvim refuses.
local function get_hl(group)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  return ok and hl or nil
end

-- The catppuccin color each chrome entry copies, read back so bootstrap's flavour carries here.
local CHROME = {
  default_fg = 'text',
  decoration = 'overlay0',
  minus_num = 'red',
  plus_num = 'green',
  hunk_num = 'subtext0',
  commit_hash = 'yellow',
  decorations_fg = 'blue',
  stat_count = 'subtext0',
}

-- The CodeDiff* group, and its attribute, each diff color is a copy of.
local CODEDIFF = {
  minus_bg = { 'CodeDiffLineDelete', 'bg' },
  minus_emph_bg = { 'CodeDiffCharDelete', 'bg' },
  plus_bg = { 'CodeDiffLineInsert', 'bg' },
  plus_emph_bg = { 'CodeDiffCharInsert', 'bg' },
  filler_fg = { 'CodeDiffFiller', 'fg' },
}

--- Copy the chrome colors out of catppuccin's palette and the diff colors out of the CodeDiff*
--- groups, once codediff.nvim's highlights.setup() has derived them.
function M.load_diff_colors()
  local pal = require('catppuccin.palettes').get_palette()
  for key, name in pairs(CHROME) do
    -- The palette hands back "#rrggbb"; the renderer works in packed ints.
    M.palette[key] = tonumber(pal[name]:sub(2), 16)
  end

  for key, source in pairs(CODEDIFF) do
    M.palette[key] = get_hl(source[1])[source[2]]
  end
end

-- Language, then capture: two reads per segment, no key built; `false` for a capture with no style.
local cache = vim.defaulttable(function(lang)
  return vim.defaulttable(function(capture)
    local hl = get_hl('@' .. capture .. '.' .. lang)
    if hl and (hl.fg or hl.bold or hl.italic or hl.underline) then
      return { fg = hl.fg, bold = hl.bold, italic = hl.italic, underline = hl.underline }
    end
    return false
  end)
end)

--- A capture's attrs, false when the theme defines none (nvim resolves the @capture link chain).
--- The table is shared and keys callers' memos by identity: never mutate it.
function M.attrs(capture, lang)
  return cache[lang][capture]
end

return M
