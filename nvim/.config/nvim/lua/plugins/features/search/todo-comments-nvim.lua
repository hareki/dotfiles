---@class snacks.picker
---@field todo_comments fun(opts?: snacks.picker.todo.Config|{}): snacks.Picker

return {
  'folke/todo-comments.nvim',
  cmd = { 'TodoTrouble', 'TodoTelescope' },
  event = 'VeryLazy',
  dependencies = { 'hareki/snacks.nvim' },
  opts = {},
  keys = {
    {
      ']t',
      function()
        local todo_comments = require('todo-comments')
        todo_comments.jump_next()
      end,
      desc = 'Next Todo Comment',
    },
    {
      '[t',
      function()
        local todo_comments = require('todo-comments')
        todo_comments.jump_prev()
      end,
      desc = 'Previous Todo Comment',
    },
    {
      '<leader>ft',
      function()
        Snacks.picker.todo_comments({ keywords = { 'TODO', 'FIXME', 'HACK' }, show_pattern = false })
      end,
      desc = 'Find Todo/Fix/Hack Comments',
    },
    {
      '<leader>fT',
      function()
        Snacks.picker.todo_comments({ show_pattern = false })
      end,
      desc = 'Find All Todo Comments',
    },
  },
}
