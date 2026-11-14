--- @class chrome.which-key-nvim.icon-rules
local M = {}

-- which-key names its nine icon colors itself and links each to a mini.icons group, which
-- catppuccin paints with these palette keys
local WHICH_KEY_COLORS = {
  sapphire = 'azure',
  blue = 'blue',
  teal = 'cyan',
  green = 'green',
  text = 'grey',
  peach = 'orange',
  mauve = 'purple',
  red = 'red',
  yellow = 'yellow',
}

--- The rules with each palette key replaced by the name which-key knows that color by, raising
--- on a key it has no color for; the rules given stay as their specs wrote them
--- @param rules utils.ui.which-key-nvim.IconRule[]
--- @return wk.IconRule[] resolved
function M.resolve_colors(rules)
  return vim.tbl_map(function(rule)
    if not rule.color then
      return rule
    end

    local color = WHICH_KEY_COLORS[rule.color]
    if not color then
      error(
        string.format(
          'Icon rule %q: which-key has no color for the palette key %q',
          rule.pattern or rule.plugin,
          rule.color
        ),
        0
      )
    end

    return vim.tbl_extend('force', rule, { color = color })
  end, rules)
end

return M
