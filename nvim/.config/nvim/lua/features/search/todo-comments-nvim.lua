--- @class snacks.picker
--- @field todo_comments fun(opts?: snacks.picker.todo.Config | {}): snacks.Picker

--- @module 'todo-comments'
local todo_comments = Defer.on_exported_call('todo-comments')

--- @module 'snacks.picker'
local picker = Defer.on_exported_call('snacks.picker')

return {
  'folke/todo-comments.nvim',
  cmd = 'TodoTrouble',
  event = 'VeryLazy',

  dependencies = { 'nvim-lua/plenary.nvim' },

  keys = {
    { ']t', todo_comments.jump_next, desc = 'Next Todo Comment' },
    { '[t', todo_comments.jump_prev, desc = 'Previous Todo Comment' },
    {
      '<leader>ft',
      function()
        Snacks.picker.todo_comments({
          -- The snacks source doesn't expand aliases, so FIX and its alts must be listed
          keywords = { 'TODO', 'FIX', 'FIXME', 'BUG', 'FIXIT', 'ISSUE', 'HACK' },
        })
      end,
      desc = 'Find Todo/Fix/Hack Comments',
    },
    { '<leader>fT', picker.todo_comments, desc = 'Find All Todo Comments' },
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
