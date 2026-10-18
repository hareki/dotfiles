local ansi = require('lib.ansi')
local diffparse = require('lib.diffparse')
local theme = require('lib.theme')
local util = require('lib.util')

local M = {}

local styled = ansi.styled

local function render_stat_line(line, p)
  local name, sep, rest = line:match('^(.-)(%s|%s)(.*)$')
  if not name then
    return nil
  end
  local out = { styled({ fg = p.default_fg }, name), styled({ fg = p.decoration }, sep) }
  -- rest is like "12 +++---", "Bin 0 -> 1024 bytes", or just a count: runs of
  -- +, of - and of anything else, each in its own color.
  local pos = 1
  while pos <= #rest do
    local run = rest:match('^%++', pos) or rest:match('^%-+', pos) or rest:match('^[^+%-]+', pos)
    local first = run:sub(1, 1)
    local fg = first == '+' and p.plus_num or first == '-' and p.minus_num or p.stat_count
    out[#out + 1] = styled({ fg = fg }, run)
    pos = pos + #run
  end
  out[#out + 1] = ansi.eol
  return table.concat(out)
end

--- Style non-diff content (commit header, message, --stat, submodule logs).
--- Needed because we ask git for uncolored output (colorArg: never).
function M.render_raw(lines, cols)
  local p = theme.palette
  local out = {}
  for _, raw in ipairs(lines) do
    -- A commit message or a submodule log is content like any diff row is.
    local line = util.display_form(raw)
    local hash, decorations = diffparse.commit_line(line)
    -- "Author: ...", "Date: ..." and friends: the label keeps the colon, the
    -- rest keeps the whitespace that separated them.
    local label, rest = line:match('^(%u%w*:)(%s.*)$')
    if hash then
      local rendered = styled({ fg = p.default_fg }, 'commit ')
        .. styled({ fg = p.commit_hash, bold = true }, hash)
      if decorations ~= '' then
        rendered = rendered .. ' ' .. styled({ fg = p.decorations_fg }, decorations)
      end
      out[#out + 1] = rendered .. ansi.eol
      local rule_width = math.min(util.display_width(line), math.max(cols - 1, 1))
      out[#out + 1] = ansi.line({ fg = p.decoration }, string.rep('─', rule_width))
    elseif label then
      out[#out + 1] = styled({ fg = p.decoration }, label)
        .. styled({ fg = p.default_fg }, rest)
        .. ansi.eol
    elseif line:match('^%s.+%s|%s') then
      out[#out + 1] = render_stat_line(line, p) or ansi.line({ fg = p.default_fg }, line)
    elseif line:match('^ %d+ files? changed') then
      out[#out + 1] = ansi.line({ fg = p.decoration }, line)
    elseif diffparse.is_submodule_line(line) then
      out[#out + 1] = ansi.line({ fg = p.default_fg, bold = true }, line)
    elseif vim.startswith(line, '  > ') then
      out[#out + 1] = ansi.line({ fg = p.plus_num }, line)
    elseif vim.startswith(line, '  < ') then
      out[#out + 1] = ansi.line({ fg = p.minus_num }, line)
    else
      out[#out + 1] = ansi.line({ fg = p.default_fg }, line)
    end
  end
  return table.concat(out)
end

--- Combined (merge) diffs (diffparse's "combined" blocks) are shown with simple
--- prefix tinting only.
function M.render_combined(block)
  local p = theme.palette
  local title = util.display_form(block.path or 'merge diff')
  local out = { ansi.line({ fg = p.default_fg, bold = true }, title) }
  for _, raw in ipairs(block.lines) do
    local line = util.display_form(raw)
    local prefix = line:sub(1, 2)
    if line:match('^@@@') then
      out[#out + 1] = ansi.line({ fg = p.hunk_num, bold = true }, line)
    elseif prefix:find('+', 1, true) and not vim.startswith(line, '+++ ') then
      out[#out + 1] = ansi.line({ fg = p.default_fg, bg = p.plus_bg }, line)
    elseif prefix:find('-', 1, true) and not vim.startswith(line, '--- ') then
      out[#out + 1] = ansi.line({ fg = p.default_fg, bg = p.minus_bg }, line)
    else
      out[#out + 1] = ansi.line({ fg = p.default_fg }, line)
    end
  end
  return table.concat(out)
end

return M
