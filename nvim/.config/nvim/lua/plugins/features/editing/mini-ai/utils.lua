---@class plugins.features.editing.mini-ai.utils
local M = {}

---Generate textobject spec for the entire buffer
---From MiniExtra.gen_ai_spec.buffer - handles 'i' (inner) and 'a' (around) types.
---@param ai_type 'a' | 'i' The textobject type ('a' includes blanks, 'i' excludes them)
---@return table spec The region spec with from/to positions
function M.buffer(ai_type)
  local bufnr = vim.api.nvim_get_current_buf()
  local start_line, end_line = 1, vim.api.nvim_buf_line_count(bufnr)
  if ai_type == 'i' then
    -- Skip first and last blank lines for `i` textobject
    local first_nonblank, last_nonblank =
      vim.fn.nextnonblank(start_line), vim.fn.prevnonblank(end_line)
    -- Do nothing for buffer with all blanks
    if first_nonblank == 0 or last_nonblank == 0 then
      return { from = { line = start_line, col = 1 } }
    end
    start_line, end_line = first_nonblank, last_nonblank
  end

  local last_line = vim.api.nvim_buf_get_lines(bufnr, end_line - 1, end_line, false)[1] or ''
  local to_col = math.max(#last_line, 1)
  return { from = { line = start_line, col = 1 }, to = { line = end_line, col = to_col } }
end

---Register all mini.ai textobjects with which-key for discoverability
---@param opts table Options with mappings (around, inside, around_next, etc.)
---@return nil
function M.whichkey(opts)
  local objects = {
    { ' ', desc = 'Whitespace' },
    { '"', desc = '" String' },
    { "'", desc = "' String" },
    { '(', desc = '() Block' },
    { ')', desc = '() Block with Ws' },
    { '<', desc = '<> Block' },
    { '>', desc = '<> Block with Ws' },
    { '?', desc = 'User Prompt' },
    { 'U', desc = 'Use/Call without Dot' },
    { '[', desc = '[] Block' },
    { ']', desc = '[] Block with Ws' },
    { '_', desc = 'Underscore' },
    { '`', desc = '` String' },
    { 'a', desc = 'Argument' },
    { 'b', desc = ')]} Block' },
    { 'c', desc = 'Class' },
    { 'd', desc = 'Digit(s)' },
    { 'f', desc = 'Function' },
    { 'g', desc = 'Entire File' },
    { 'i', desc = 'Indent' },
    { 'o', desc = 'Block, Conditional, Loop' },
    { 'q', desc = 'Quote `"\'' },
    { 't', desc = 'Tag' },
    { 'u', desc = 'Use/Call' },
    { 'w', desc = 'Subword (camelCase/snake_case)' },
    { 'W', desc = 'WORD (snake_case chunk)' },
    { '{', desc = '{} Block' },
    { '}', desc = '{} with Ws' },
  }

  ---@type wk.Spec[]
  local ret = { mode = { 'o', 'x' } }
  ---@type table<string, string>
  local mappings = vim.tbl_extend('force', {}, {
    around = 'a',
    inside = 'i',
    around_next = 'an',
    inside_next = 'in',
    around_last = 'al',
    inside_last = 'il',
  }, opts.mappings or {})

  mappings.goto_left = nil
  mappings.goto_right = nil

  for name, prefix in pairs(mappings) do
    name = name:gsub('^around_', ''):gsub('^inside_', '')
    ret[#ret + 1] = { prefix, group = name }
    for _, obj in ipairs(objects) do
      local desc = obj.desc

      if prefix:sub(1, 1) == 'i' then
        desc = desc:gsub(' with ws', '')
      end

      ret[#ret + 1] = { prefix .. obj[1], desc = obj.desc }
    end
  end
  local which_key = require('which-key')
  which_key.add(ret, { notify = false })
end

return M
