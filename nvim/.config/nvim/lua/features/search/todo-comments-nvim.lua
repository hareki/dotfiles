--- @class snacks.picker
--- @field todo_comments fun(opts?: snacks.picker.todo.Config | {}): snacks.Picker

--- @module 'todo-comments'
local todo_comments = Defer.on_exported_call('todo-comments')

return {
  'folke/todo-comments.nvim',
  cmd = 'TodoTrouble',
  event = 'VeryLazy',

  keys = {
    { ']t', todo_comments.jump_next, desc = 'Next Todo Comment' },
    { '[t', todo_comments.jump_prev, desc = 'Previous Todo Comment' },
    {
      '<leader>ft',
      function()
        Snacks.picker.todo_comments({
          -- The snacks source builds the regex verbatim from these strings
          -- (no alias expansion), so FIX and its alts must be listed explicitly
          keywords = { 'TODO', 'FIX', 'FIXME', 'BUG', 'FIXIT', 'ISSUE', 'HACK' },
        })
      end,
      desc = 'Find Todo/Fix/Hack Comments',
    },
    {
      '<leader>fT',
      function()
        Snacks.picker.todo_comments()
      end,
      desc = 'Find All Todo Comments',
    },
  },

  opts = function()
    return {
      keywords = {
        FIX = { icon = Conf.icons.tools.DEBUG },
      },
      highlight = {
        multiline = false,
        keyword = 'wide_bg',
        after = '',
      },
    }
  end,
}
