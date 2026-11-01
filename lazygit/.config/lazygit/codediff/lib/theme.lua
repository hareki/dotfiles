local M = {}

-- Chrome colors (headers, notes, --stat, commit metadata) mirror the delta
-- catppuccin-mocha theme from ~/.gitconfig. load_diff_colors(), which bootstrap
-- runs before anything renders, fills this from the live colorscheme -- the chrome
-- entries from catppuccin's own palette, the diff colors from the CodeDiff*
-- groups -- so lazygit shows exactly what codediff.nvim shows in the editor;
-- syntax colors come from catppuccin at runtime.
M.palette = {}

--- Fully resolved attrs of a highlight group (empty when it is undefined), or
--- nil for a name nvim refuses.
local function get_hl(group)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  return ok and hl or nil
end

-- The catppuccin color each chrome entry is a copy of. catppuccin is loaded in
-- this process already (bootstrap puts it on the rtp and calls its setup), so
-- the palette is read back rather than transcribed a second time: a flavour
-- change in bootstrap then carries here on its own.
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

--- Copy the chrome colors out of catppuccin's palette and the diff colors out
--- of the CodeDiff* groups. Must run after codediff.nvim's
--- highlights.setup() has derived them from the colorscheme.
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

-- Nested by language then capture, so the lookup on the renderer's hot path
-- costs two table reads instead of a composite key built per segment. `false`
-- records a capture the theme defines nothing for.
local cache = vim.defaulttable(function(lang)
  return vim.defaulttable(function(capture)
    local hl = get_hl('@' .. capture .. '.' .. lang)
    if hl and (hl.fg or hl.bold or hl.italic or hl.underline) then
      return { fg = hl.fg, bold = hl.bold, italic = hl.italic, underline = hl.underline }
    end
    return false
  end)
end)

--- Resolve a treesitter capture to highlight attrs. nvim maintains the default
--- link chain for @capture groups itself (@function.call.lua => @function.call
--- => @function, see :h treesitter-highlight-groups), so resolving the most
--- specific name is enough. Returns false when the theme defines nothing (render
--- with the default fg).
---
--- The returned table is shared and must not be mutated: callers key their own
--- memos on its identity.
function M.attrs(capture, lang)
  return cache[lang][capture]
end

return M
