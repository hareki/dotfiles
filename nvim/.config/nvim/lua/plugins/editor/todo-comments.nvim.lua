---@class snacks.picker
---@field todo_comments fun(opts?: snacks.picker.todo.Config|{}): snacks.Picker

return {
  'folke/todo-comments.nvim',
  cmd = { 'TodoTrouble', 'TodoTelescope' },
  event = { 'BufReadPost', 'BufNewFile', 'BufWritePre' },
  dependencies = { 'hareki/snacks.nvim' },
  opts = {},
  keys = {
    {
      ']t',
      function()
        require('todo-comments').jump_next()
      end,
      desc = 'Next Todo Comment',
    },
    {
      '[t',
      function()
        require('todo-comments').jump_prev()
      end,
      desc = 'Previous Todo Comment',
    },
    {
      '<leader>ft',
      function()
        Snacks.picker.todo_comments({ keywords = { 'TODO', 'FIXME', 'HACK' }, show_pattern = false })
      end,
      desc = 'Show Todo/Fix/Hack Comments',
    },
    {
      '<leader>fT',
      function()
        Snacks.picker.todo_comments({ show_pattern = false })
      end,
      desc = 'Show All Todo Comments',
    },
  },
}
