local prefix = 'Debug Prints: '

--- @module 'debugprint'
local debugprint = Defer.on_exported_call('debugprint')

return {
  UI.which_key({
    specs = { '<leader>?', group = 'Debug' },
    rules = { plugin = 'debugprint.nvim', icon = Conf.Icons.tools.debug, color = 'red' },
  }),

  {
    'andrewferrier/debugprint.nvim',
    keys = function()
      return {
        {
          '<leader>f?',
          '<cmd>Debugprint search<cr>',
          desc = prefix .. 'Find',
        },
        {
          '<leader>?r',
          '<cmd>Debugprint resetcounter<cr>',
          desc = prefix .. 'Reset Counter',
        },
        {
          '<leader>?d',
          '<cmd>Debugprint delete<cr>',
          desc = prefix .. 'Delete All',
        },
        {
          '<leader>?t',
          '<cmd>Debugprint commenttoggle<cr>',
          desc = prefix .. 'Toggle Comments',
        },
        {
          '<leader>?v',
          function()
            debugprint.debugprint({
              variable = true,
            })
          end,
          desc = prefix .. 'Put Variable Below',
        },
        {
          '<leader>?V',
          function()
            debugprint.debugprint({
              variable = true,
              surround = true,
            })
          end,
          desc = prefix .. 'Put Variable Surround',
        },
        {
          '<leader>?p',
          function()
            debugprint.debugprint({})
          end,
          desc = prefix .. 'Put Plain Text Below',
        },
      }
    end,

    opts = function()
      local js_like = {
        left = 'console.log("',
        right = '")',
        mid_var = '", ',
        right_var = ')',
      }

      return {
        picker = 'snacks.picker',
        picker_title = 'Debug Prints',
        highlight_lines = false,
        filetypes = (function()
          local fts = {}
          for _, ft in ipairs(Conf.Filetypes.js_all) do
            fts[ft] = js_like
          end
          return fts
        end)(),
        -- Turn off all keymaps by default for performance reasons (mapping overhead + can't lazy load)
        -- Also, I want to customize the descriptions
        keymaps = {
          insert = {
            plain = false,
            variable = false,
          },
          visual = {
            variable_below = false,
            variable_above = false,
          },

          normal = {
            plain_below = false,
            plain_above = false,
            variable_below = false,
            variable_above = false,
            variable_below_alwaysprompt = false,
            variable_above_alwaysprompt = false,
            surround_plain = false,
            surround_variable = false,
            surround_variable_alwaysprompt = false,
            textobj_below = false,
            textobj_above = false,
            textobj_surround = false,
            toggle_comment_debug_prints = false,
            delete_debug_prints = false,
          },
        },
      }
    end,
  },
}
