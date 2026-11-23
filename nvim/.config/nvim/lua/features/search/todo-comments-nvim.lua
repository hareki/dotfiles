--- @class snacks.picker
--- @field todo_comments fun(opts?: snacks.picker.todo.Config | {}): snacks.Picker

--- @module 'todo-comments'
local todo_comments = Defer.on_exported_call('todo-comments')

--- @module 'snacks.picker'
local picker = Defer.on_exported_call('snacks.picker')

return {
  {
    'snacks.nvim',
    opts = {
      picker = {
        sources = {
          todo_comments = {
            show_pattern = false,
            actions = {
              -- In this source, <C-t> opens Trouble's todo view, filtered to the picker's keywords
              --- @param todo_picker snacks.Picker
              snacks_to_trouble = function(todo_picker)
                local keywords = todo_picker
                  --- @module "todo-comments"
                  .opts --[[@as snacks.picker.todo.Config]]
                  .keywords

                todo_picker:close()
                local trouble = require('trouble')
                --- @diagnostic disable-next-line: missing-fields
                trouble.toggle({
                  mode = 'todo',
                  filter = keywords and { tag = keywords },
                })
              end,
            },
          },
        },
      },
    },
  },

  {
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
  },
}
