local M = {}

--- Extract per-row highlight spans from a source string, mirroring
--- vim.treesitter.highlighter semantics: injected trees are walked after their
--- parent and later spans win ties, priorities from `#set! priority` respected.
---
--- content:    full source text
--- lang:       treesitter language (parser must be loadable)
--- row_ranges: sorted, merged list of {start_row, end_row} (0-based, inclusive)
---             restricting extraction to the rows the diff actually shows
---
--- Returns rows: { [row0] = { {s=col0, e=col_end_excl, capture, lang, prio, order}, ... } }
--- or nil when parsing is unavailable.
function M.line_spans(content, lang, row_ranges)
  local ok, parser = pcall(vim.treesitter.get_string_parser, content, lang)
  if not ok or not parser then
    return nil
  end
  -- Parse only the span the diff actually shows, not the whole document: the
  -- rows outside it are never queried, and injection discovery over them is the
  -- single most expensive part of highlighting a large file.
  local first, last = row_ranges[1], row_ranges[#row_ranges]
  local parse_ok = pcall(parser.parse, parser, first and { first[1], last[2] + 1 } or true)
  if not parse_ok then
    return nil
  end

  local needed = {}
  for _, range in ipairs(row_ranges) do
    for r = range[1], range[2] do
      needed[r] = true
    end
  end

  local rows = {}
  local seen = {}
  local order = 0

  local function add_span(span_lang, name, sr, sc, er, ec, prio)
    local key = table.concat({ span_lang, name, sr, sc, er, ec }, ":")
    if seen[key] then
      return
    end
    seen[key] = true
    order = order + 1
    for r = sr, er do
      if needed[r] then
        local s = r == sr and sc or 0
        local e = r == er and ec or math.huge
        if e > s then
          local row = rows[r]
          if not row then
            row = {}
            rows[r] = row
          end
          row[#row + 1] = { s = s, e = e, capture = name, lang = span_lang, prio = prio, order = order }
        end
      end
    end
  end

  local function collect(langtree)
    local tree_lang = langtree:lang()
    local query_ok, query = pcall(vim.treesitter.query.get, tree_lang, "highlights")
    if query_ok and query then
      for _, tree in pairs(langtree:trees()) do
        local root = tree:root()
        for _, range in ipairs(row_ranges) do
          for id, node, metadata in query:iter_captures(root, content, range[1], range[2] + 1) do
            local name = query.captures[id]
            if name ~= "spell" and name ~= "nospell" and name ~= "conceal" and name:sub(1, 1) ~= "_" then
              local prio = tonumber(metadata.priority or (metadata[id] and metadata[id].priority))
                or vim.hl.priorities.treesitter
              local sr, sc, er, ec
              local meta_range = metadata[id] and metadata[id].range
              if meta_range then
                sr, sc, er, ec = meta_range[1], meta_range[2], meta_range[3], meta_range[4]
              else
                sr, sc, er, ec = node:range()
              end
              add_span(tree_lang, name, sr, sc, er, ec, prio)
            end
          end
        end
      end
    end
    for _, child in pairs(langtree:children()) do
      collect(child)
    end
  end

  local walk_ok = pcall(collect, parser)
  if not walk_ok and not next(rows) then
    return nil
  end
  return rows
end

--- Merge the row ranges a file's hunks need on one side, with padding rows so
--- constructs straddling hunk edges are captured. 0-based inclusive ranges.
function M.needed_ranges(hunks, side, pad)
  local ranges = {}
  for _, hunk in ipairs(hunks) do
    local start_row, count
    if side == "old" then
      start_row, count = hunk.old_start - 1, hunk.old_count
    else
      start_row, count = hunk.new_start - 1, hunk.new_count
    end
    local s = math.max(0, start_row - pad)
    local e = start_row + math.max(count, 1) - 1 + pad
    local last = ranges[#ranges]
    if last and s <= last[2] + 1 then
      last[2] = math.max(last[2], e)
    else
      ranges[#ranges + 1] = { s, e }
    end
  end
  return ranges
end

return M
