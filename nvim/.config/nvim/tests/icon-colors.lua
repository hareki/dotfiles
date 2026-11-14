-- The colors icons take. Icon rules are written in Catppuccin palette keys, which
-- chrome.which-key-nvim.icon-rules turns into which-key's own names, and a statusline piece takes
-- the same keys; neither accepts a key the palette lacks

local t = require('tests.lib.helpers')
local icon_rules = require('chrome.which-key-nvim.icon-rules')
local lualine_utils = require('chrome.lualine-nvim.utils')

-- The palette keys which-key has a color for
local KEYS = { 'sapphire', 'blue', 'teal', 'green', 'text', 'peach', 'mauve', 'red', 'yellow' }

--- @param hex string As the palette spells a color, `#rrggbb`
--- @return integer
local function rgb(hex)
  return tonumber(hex:sub(2), 16) --[[@as integer]]
end

t.test('a rule in each palette key paints its which-key icon in that color', function()
  local wk_icons = require('which-key.icons')
  local palette = UI.catppuccin.get_palette()
  -- which-key links its icon groups to mini.icons' in a scheduled step of its load
  t.wait_for(function()
    return vim.api.nvim_get_hl(0, { name = 'WhichKeyIconBlue', link = false }).fg ~= nil
  end, "which-key's icon groups")

  for _, key in ipairs(KEYS) do
    local rule = icon_rules.resolve_colors({ { pattern = 'probe', icon = 'x', color = key } })[1]
    local _, group = wk_icons.get_icon(rule)
    local painted = vim.api.nvim_get_hl(0, { name = group, link = false }).fg
    t.eq(painted, rgb(palette[key]), string.format('%s, through %s', key, group))
  end
end)

t.test('resolving leaves the rules as their specs wrote them, colorless ones included', function()
  local written =
    { { pattern = 'pin', icon = 'x', color = 'teal' }, { pattern = 'next', icon = 'y' } }
  local resolved = icon_rules.resolve_colors(written)

  t.eq(written[1].color, 'teal', 'the rule given keeps its palette key')
  t.eq(resolved[1], { pattern = 'pin', icon = 'x', color = 'cyan' }, 'the resolved rule')
  t.eq(resolved[2], { pattern = 'next', icon = 'y' }, 'a rule without a color')
end)

t.test("which-key's own color names and keys it has no color for are refused", function()
  for _, color in ipairs({ 'cyan', 'purple', 'lavender' }) do
    -- The rule's type refuses them as well
    --- @diagnostic disable-next-line: assign-type-mismatch
    local ok, err = pcall(icon_rules.resolve_colors, { { pattern = 'probe', color = color } })
    t.eq(ok, false, color)
    t.ok(tostring(err):find(color, 1, true), 'the error names the key: ' .. tostring(err))
  end
end)

t.test('a statusline piece takes a palette key and refuses anything else', function()
  local palette = UI.catppuccin.get_palette()
  local function piece(color)
    return lualine_utils.create_styling_wrapper({
      type = 'secondary-right',
      comp = 'probe',
      icon = 'x',
      color = color,
    })[1]
  end

  t.eq(piece('teal').color.fg, palette.teal, 'a palette key')
  t.eq(piece(nil).color.fg, palette.subtext0, 'no color defaults to subtext0')
  t.eq(pcall(piece, 'cyan'), false, "which-key's name for teal")
end)

t.test('every rule which-key was set up with carries one of its own color names', function()
  local wk_config = require('which-key.config')
  local names = {}
  for _, key in ipairs(KEYS) do
    names[icon_rules.resolve_colors({ { pattern = 'probe', color = key } })[1].color] = true
  end

  local colored = 0
  for _, rule in ipairs(wk_config.icons.rules) do
    if rule.color then
      colored = colored + 1
      t.ok(names[rule.color], string.format('%s: %s', rule.pattern or rule.plugin, rule.color))
    end
  end
  t.ok(colored > 0, 'no rule carries a color')
end)
