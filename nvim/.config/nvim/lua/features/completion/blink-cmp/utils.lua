--- @class features.completion.blink-cmp.utils
local M = {}
--- @alias TransformItems fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): blink.cmp.CompletionItem[]

--- Return a table with a transform_items that tags every item with a custom kind
--- through blink's per-item overrides: the icon resolves from
--- appearance.kind_icons[name], and kind_hl is set too since blink derives the
--- default one from the numeric kind.
--- @param name string Kind name (e.g. 'History', 'Spell')
--- @return { transform_items: TransformItems }
function M.custom_kind(name)
  local kind_hl = 'BlinkCmpKind' .. name

  --- @type TransformItems
  local function transform_items(_, items)
    for _, item in ipairs(items) do
      item.kind_name = name
      item.kind_hl = kind_hl
    end
    return items
  end

  return { transform_items = transform_items }
end

return M
