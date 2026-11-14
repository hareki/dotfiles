--- An icon rule's color: which-key paints the icon with the group `WhichKeyIcon<Color>`,
--- capitalizing whatever the rule names, so a group per Catppuccin palette key lets a rule name its
--- color as the rest of the config does
--- @class chrome.which-key-nvim.icon-rules
local M = {}

--- @param palette utils.ui.catppuccin-nvim.Palette
--- @return table<string, vim.api.keyset.highlight> groups One per palette key
function M.highlights(palette)
  local groups = {}
  for key, hex in pairs(palette) do
    groups['WhichKeyIcon' .. key:sub(1, 1):upper() .. key:sub(2)] = { fg = hex }
  end
  return groups
end

--- Raise on a rule whose color is no palette key: which-key's own name for one would paint through
--- which-key's group, a typo through none
--- @param rules utils.ui.which-key-nvim.IconRule[]
function M.check_colors(rules)
  local palette = UI.catppuccin.get_palette()
  for _, rule in ipairs(rules) do
    if rule.color and not palette[rule.color] then
      error(
        string.format('Icon rule %q: %q is no palette key', rule.pattern or rule.plugin, rule.color),
        0
      )
    end
  end
end

return M
