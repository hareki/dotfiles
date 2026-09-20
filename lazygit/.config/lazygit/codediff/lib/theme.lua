local M = {}

-- Chrome colors (headers, notes, --stat, commit metadata) mirror the delta
-- catppuccin-mocha theme from ~/.gitconfig. Every value here is a placeholder
-- that load_diff_colors() overwrites from the live colorscheme -- the chrome
-- entries from catppuccin's own palette, the four diff backgrounds from the
-- CodeDiff* groups -- so lazygit shows exactly what codediff.nvim shows in the
-- editor; syntax colors come from catppuccin at runtime. The literals are the
-- values that resolution produces today, and stand in only for a render that
-- reaches this module without bootstrap having run.
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

--- Fully resolved attrs of a highlight group, or nil when it is undefined.
local function get_hl(group)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  if ok and hl then
    return hl
  end
  return nil
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

--- Copy the chrome colors out of catppuccin's palette and the diff backgrounds
--- out of the CodeDiff* groups. Must run after codediff.nvim's
--- highlights.setup() has derived them from the colorscheme.
function M.load_diff_colors()
  local ok, pal = pcall(function()
    return require('catppuccin.palettes').get_palette()
  end)
  if ok and type(pal) == 'table' then
    for key, name in pairs(CHROME) do
      -- The palette hands back "#rrggbb"; the renderer works in packed ints.
      local hex = pal[name]
      local rgb = type(hex) == 'string' and tonumber(hex:sub(2), 16) or nil
      if rgb then
        M.palette[key] = rgb
      end
    end
  end

  local map = {
    minus_bg = 'CodeDiffLineDelete',
    minus_emph_bg = 'CodeDiffCharDelete',
    plus_bg = 'CodeDiffLineInsert',
    plus_emph_bg = 'CodeDiffCharInsert',
  }
  for key, group in pairs(map) do
    local hl = get_hl(group)
    if hl and hl.bg then
      M.palette[key] = hl.bg
    end
  end
  local filler = get_hl('CodeDiffFiller')
  if filler and filler.fg then
    M.palette.filler_fg = filler.fg
  end
end

-- Nested by language then capture, so the lookup on the renderer's hot path
-- costs two table reads instead of a composite key built per segment.
local cache = {}

--- Resolve a treesitter capture to highlight attrs. nvim maintains the default
--- link chain for @capture groups itself (@function.call.lua => @function.call
--- => @function, see :h treesitter-highlight-groups), so resolving the most
--- specific name is enough. Returns nil when the theme defines nothing (render
--- with the default fg).
---
--- The returned table is shared and must not be mutated: callers key their own
--- memos on its identity.
function M.attrs(capture, lang)
  local by_capture = cache[lang]
  if not by_capture then
    by_capture = {}
    cache[lang] = by_capture
  end
  local hit = by_capture[capture]
  if hit ~= nil then
    return hit or nil
  end

  local hl = get_hl('@' .. capture .. '.' .. lang)
  local attrs = nil
  if hl and (hl.fg or hl.bold or hl.italic or hl.underline) then
    attrs = { fg = hl.fg, bold = hl.bold, italic = hl.italic, underline = hl.underline }
  end

  by_capture[capture] = attrs or false
  return attrs
end

return M
