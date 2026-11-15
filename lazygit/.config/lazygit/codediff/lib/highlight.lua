local M = {}

-- Captures that style nothing, `_`-prefixed ones being a query's private scratch names.
local SKIP = { spell = true, nospell = true, conceal = true }
local UNDERSCORE = string.byte('_')

--- Per-row highlight spans, ordered as vim.treesitter.highlighter does: injections after their
--- parent, later spans winning ties, `#set! priority` respected.
---
--- lines:      full source, one string per row
--- lang:       treesitter language (parser must be loadable)
--- row_ranges: sorted {start_row, end_row} (0-based, end-exclusive), the rows the diff shows
--- deadline:   vim.uv.hrtime() value; past it, collection stops between query windows
---
--- Returns { [row0] = { {s1=col, e1=col_end_excl, capture, lang, prio, order}, ... } } with 1-based
--- columns, or nil (no parser, or the deadline already past), and whether the deadline cut rows.
function M.line_spans(lines, lang, row_ranges, deadline)
  if vim.uv.hrtime() > deadline then
    return nil, true
  end
  local content = table.concat(lines, '\n')
  local ok, parser = pcall(vim.treesitter.get_string_parser, content, lang)
  if not ok or not parser then
    return nil
  end
  -- Only the shown rows: injection discovery over the rest is the costliest part of a large file.
  local parse_ok = pcall(parser.parse, parser, row_ranges)
  if not parse_ok then
    return nil
  end

  local needed = {}
  for _, range in ipairs(row_ranges) do
    for r = range[1], range[2] - 1 do
      needed[r] = true
    end
  end

  local rows = {}
  -- Whether some of the collection was skipped, which is what the caller is told.
  local expired = false
  local seen = {}
  local order = 0
  local default_prio = vim.hl.priorities.treesitter

  local function add_span(span_lang, name, sr, sc, er, ec, prio)
    -- Overlapping windows report a straddling node once each, and two patterns capturing one name
    -- report it twice: a duplicate would outrank the span that rightly won the tie.
    local key = span_lang .. '\0' .. name .. '\0' .. sr .. ':' .. sc .. ':' .. er .. ':' .. ec
    if seen[key] then
      return
    end
    seen[key] = true
    order = order + 1
    for r = sr, er do
      if needed[r] then
        local s1 = r == sr and sc + 1 or 1
        local e1 = r == er and ec + 1 or math.huge
        if e1 > s1 then
          local row = rows[r]
          if not row then
            row = {}
            rows[r] = row
          end
          row[#row + 1] =
            { s1 = s1, e1 = e1, capture = name, lang = span_lang, prio = prio, order = order }
        end
      end
    end
  end

  local function collect(tree, langtree)
    local tree_lang = langtree:lang()
    local query_ok, query = pcall(vim.treesitter.query.get, tree_lang, 'highlights')
    if not query_ok or not query then
      return
    end
    local captures = query.captures
    local root = tree:root()
    -- Skip windows the injected tree doesn't reach: each would cost a cursor setup for nothing.
    local tree_first, _, tree_last, _ = root:range()
    for _, range in ipairs(row_ranges) do
      -- Between windows, never inside one: an hrtime call is nothing next to a window's captures.
      if vim.uv.hrtime() > deadline then
        expired = true
        return
      end
      if range[1] <= tree_last and range[2] > tree_first then
        for id, node, metadata in query:iter_captures(root, content, range[1], range[2]) do
          local name = captures[id]
          if not SKIP[name] and name:byte(1) ~= UNDERSCORE then
            local meta = metadata[id]
            local prio = tonumber(metadata.priority or (meta and meta.priority)) or default_prio
            local sr, sc, er, ec
            if meta and (meta.range or meta.offset) then
              -- #trim! leaves a range, #offset! only offsets (0.12); get_range takes both. Range6.
              local r = vim.treesitter.get_range(node, content, meta)
              sr, sc, er, ec = r[1], r[2], r[4], r[5]
            else
              sr, sc, er, ec = node:range()
            end
            add_span(tree_lang, name, sr, sc, er, ec, prio)
          end
        end
      end
    end
  end

  pcall(parser.for_each_tree, parser, collect)
  return rows, expired
end

return M
