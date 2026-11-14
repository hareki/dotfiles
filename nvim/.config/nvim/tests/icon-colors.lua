-- The colors icons take. An icon rule names its color by Catppuccin palette key, which which-key
-- paints through the group chrome.which-key-nvim.icon-rules defines for that key, and a statusline
-- piece takes the same keys; neither accepts a key the palette lacks

local t = require('tests.lib.helpers')
local icon_rules = require('chrome.which-key-nvim.icon-rules')
local lualine_utils = require('chrome.lualine-nvim.utils')

--- @param group? string A highlight group, as which-key names the one of an icon
--- @return string? hex Its foreground as the palette spells a color, `#rrggbb`
local function fg(group)
  return Snacks.util.color(t.ok(group, 'the icon has no highlight group'))
end

--- Fail unless a rule in each palette key paints its which-key icon in that color
local function expect_every_key_painted()
  local wk_icons = require('which-key.icons')
  for key, hex in pairs(UI.catppuccin.get_palette()) do
    --- @type utils.ui.which-key-nvim.IconRule
    local rule = { icon = 'x', color = key }
    local _, group = wk_icons.get_icon(rule)
    t.eq(fg(group), hex, string.format('%s, through %s', key, group))
  end
end

t.test('a rule in each palette key paints its which-key icon in that color', function()
  expect_every_key_painted()
end)

t.test("which-key's own color names and other keys the palette lacks are refused", function()
  for _, color in ipairs({ 'cyan', 'purple', 'tael' }) do
    -- The rule's type refuses them as well
    --- @diagnostic disable-next-line: assign-type-mismatch
    local ok, err = pcall(icon_rules.check_colors, { { pattern = 'probe', color = color } })
    t.eq(ok, false, color)
    t.ok(tostring(err):find(color, 1, true), 'the error names the key: ' .. tostring(err))
  end

  icon_rules.check_colors({ { pattern = 'pin', color = 'lavender' }, { pattern = 'next' } })
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

t.test('the tab and the file tree paint one color on every surface', function()
  local wk_icons = require('which-key.icons')
  local tab_piece = require('chrome.lualine-nvim.components.tab')
  local palette = UI.catppuccin.get_palette()

  local tab = palette[Conf.icons.colors.TAB]
  local _, tab_rule = wk_icons.get({ desc = 'Next Tab' })
  t.eq(fg(tab_rule), tab, "the tab's which-key icon")
  t.eq(fg('SnacksPickerTabName'), tab, 'the tabs picker label')
  t.eq(palette[tab_piece.color], tab, 'the statusline tab pill')

  local tree = palette[Conf.icons.colors.TREE]
  local _, tree_rule = wk_icons.get({ keymap = { lhs = '<leader>e', mode = 'n' } })
  t.eq(fg(tree_rule), tree, "the file tree's which-key icon")
  t.eq(fg('DropBarIconTree'), tree, "the file tree's winbar title")
end)

t.test('every colored rule which-key was set up with paints its palette key', function()
  local wk_config = require('which-key.config')
  local wk_icons = require('which-key.icons')
  local palette = UI.catppuccin.get_palette()

  local colored = 0
  for _, rule in ipairs(wk_config.icons.rules) do
    if rule.color then
      colored = colored + 1
      local _, group = wk_icons.get_icon(rule)
      t.eq(fg(group), palette[rule.color], rule.pattern or rule.plugin)
    end
  end
  t.ok(colored > 0, 'no rule carries a color')
end)

t.test('a colorscheme reload keeps the icon colors', function()
  vim.cmd.colorscheme(vim.g.colors_name)
  expect_every_key_painted()
end)
