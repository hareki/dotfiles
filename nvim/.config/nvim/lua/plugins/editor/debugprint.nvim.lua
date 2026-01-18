return {
  'andrewferrier/debugprint.nvim',
  keys = function()
    return {
      {
        '<leader>f?',
        '<CMD>Debugprint search<CR>',
        desc = 'Debug Prints: Find',
      },
      {
        '<leader>?r',
        '<CMD>Debugprint resetcounter<CR>',
        desc = 'Debug Prints: Reset Counter',
      },
      {
        '<leader>?d',
        '<CMD>Debugprint delete<CR>',
        desc = 'Debug Prints: Delete All',
      },
      {
        '<leader>?t',
        '<CMD>Debugprint commenttoggle<CR>',
        desc = 'Debug Prints: Toggle Comments',
      },
      {
        '<leader>?v',
        function()
          require('debugprint').debugprint({
            variable = true,
          })
        end,
        desc = 'Debug Prints: Put Variable Below',
      },
      {
        '<leader>?V',
        function()
          require('debugprint').debugprint({
            variable = true,
            surround = true,
          })
        end,
        desc = 'Debug Prints: Put Variable Surround',
      },
      {
        '<leader>?p',
        function()
          require('debugprint').debugprint({})
        end,
        desc = 'Debug Prints: Put Plain Text Below',
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
      filetypes = {
        ['javascript'] = js_like,
        ['javascriptreact'] = js_like,
        ['typescript'] = js_like,
        ['typescriptreact'] = js_like,
      },
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
}
