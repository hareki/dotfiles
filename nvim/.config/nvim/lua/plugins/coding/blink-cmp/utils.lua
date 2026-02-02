---@class blink-cmp.utils
local M = {}
---@alias TransformItems fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): blink.cmp.CompletionItem[]

---Returns a function that yields min keyword length for cmdline (or 0). Used so cmdline completion waits until after the first space.
---@param length number|nil Minimum length when in cmdline before first space (default 3)
---@return fun(ctx: table): number
function M.cmdline_min_keyword_length(length)
  return function(ctx)
    -- When typing a command, only show when the keyword is 3 characters or longer
    if ctx.mode == 'cmdline' and string.find(ctx.line, ' ') == nil then
      return length or 3
    end

    return 0
  end
end

---Register a completion item kind and return a table with a transform_items that sets that kind on all items.
---@param name string Kind name (e.g. 'History', 'Spell')
---@return { transform_items: TransformItems }
function M.register_kind(name)
  local cmp_types = require('blink.cmp.types')
  local CompletionItemKind = cmp_types.CompletionItemKind
  local kind_index = CompletionItemKind[name]

  if not kind_index then
    kind_index = #CompletionItemKind + 1
    CompletionItemKind[kind_index] = name
    CompletionItemKind[name] = kind_index
  end

  ---@type TransformItems
  local function transform_items(_, items)
    for _, item in ipairs(items) do
      item.kind = kind_index
    end
    return items
  end

  return { transform_items = transform_items }
end

return M
