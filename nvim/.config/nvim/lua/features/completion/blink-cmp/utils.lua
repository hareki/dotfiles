--- @class features.completion.blink-cmp.utils
local M = {}
--- @alias features.completion.blink-cmp.utils.TransformItems fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): blink.cmp.CompletionItem[]

--- A transform_items tagging every item with a custom kind: the icon resolves from
--- appearance.kind_icons[name], and kind_hl is set since blink derives it from the numeric kind
--- @param name string Kind name (e.g. 'History', 'Spell')
--- @return features.completion.blink-cmp.utils.TransformItems
function M.custom_kind(name)
  local kind_hl = 'BlinkCmpKind' .. name

  return function(_, items)
    for _, item in ipairs(items) do
      item.kind_name = name
      item.kind_hl = kind_hl
    end
    return items
  end
end

return M
