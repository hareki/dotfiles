--- @class features.editing.mini-ai.utils
local M = {}

--- @class features.editing.mini-ai.utils.State
--- @field last_obj string? Keys of the last selected text object

--- @type features.editing.mini-ai.utils.State
M.state = {
  last_obj = nil,
}

--- Record every text object mini.ai selects, and map visual `.` to select the last one again
--- @return nil
function M.setup_repeat()
  vim.api.nvim_create_autocmd('User', {
    group = vim.api.nvim_create_augroup(
      'features.editing.mini-ai.record-last-object',
      { clear = true }
    ),
    pattern = 'MiniAiSelectObject',
    callback = function(ev)
      M.state.last_obj = ev.data -- "iw", "af", "ag", ...
    end,
  })

  vim.keymap.set('x', '.', function()
    local last_obj = M.state.last_obj
    if last_obj then
      vim.api.nvim_feedkeys(
        vim.keycode(last_obj),
        'x',
        false -- keycode() already escaped K_SPECIAL
      )
    end
  end, { desc = 'Repeat Last Text-Object Selection' })
end

--- Generate textobject spec for the entire buffer
--- From MiniExtra.gen_ai_spec.buffer
--- @param ai_type 'a' | 'i' The textobject type ('a' includes blanks, 'i' excludes them)
--- @return table spec The region spec with from/to positions
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

  local last_line = vim.api.nvim_buf_get_lines(bufnr, end_line - 1, end_line, false)[1]
  local to_col = math.max(#last_line, 1)
  return { from = { line = start_line, col = 1 }, to = { line = end_line, col = to_col } }
end

--- Register all mini.ai textobjects with which-key for discoverability
--- @return nil
function M.whichkey()
  local objects = {
    { ' ', desc = 'Whitespace' },
    { '"', desc = '" String' },
    { "'", desc = "' String" },
    { '(', desc = '() Block' },
    { ')', desc = '() Block with Whitespace' },
    { '<', desc = '<> Block' },
    { '>', desc = '<> Block with Whitespace' },
    { '?', desc = 'User Prompt' },
    { 'U', desc = 'Use/Call Without Dot' },
    { '[', desc = '[] Block' },
    { ']', desc = '[] Block with Whitespace' },
    { '_', desc = 'Underscore' },
    { '`', desc = '` String' },
    { 'a', desc = 'Argument' },
    { 'b', desc = ')]} Block' },
    { 'c', desc = 'Class' },
    { 'd', desc = 'Digit(s)' },
    { 'f', desc = 'Function' },
    { 'g', desc = 'Entire File' },
    { 'o', desc = 'Block, Conditional, Loop' },
    { 'q', desc = 'Quote `"\'' },
    { 't', desc = 'Tag' },
    { 'u', desc = 'Use/Call' },
    { 'w', desc = 'Subword (camelCase/snake_case)' },
    { 'W', desc = 'WORD (snake_case Chunk)' },
    { '{', desc = '{} Block' },
    { '}', desc = '{} Block with Whitespace' },
  }

  --- @type wk.Spec[]
  local ret = { mode = { 'o', 'x' } }
  --- @type table<string, string>
  local mappings = {
    Around = 'a',
    Inside = 'i',
    ['Around Next'] = 'an',
    ['Inside Next'] = 'in',
    ['Around Last'] = 'al',
    ['Inside Last'] = 'il',
  }

  for name, prefix in pairs(mappings) do
    ret[#ret + 1] = { prefix, group = name }
    for _, obj in ipairs(objects) do
      local desc = obj.desc

      if prefix:sub(1, 1) == 'i' then
        desc = desc:gsub(' with Whitespace', '')
      end

      ret[#ret + 1] = { prefix .. obj[1], desc = desc }
    end
  end
  local which_key = require('which-key')
  which_key.add(ret, { notify = false })
end

return M
