return {
  'hareki/debugprint.nvim',
  keys = {
    {
      '<leader>f?',
      function()
        require('debugprint.printtag_operations').show_debug_prints_fuzzy_finder()
      end,
      desc = 'Debug prints',
    },
    {
      '<leader>?r',
      function()
        require('debugprint.counter').reset_debug_prints_counter()
      end,
      desc = 'Reset counter',
    },
    {
      '<leader>?d',
      function()
        require('debugprint.printtag_operations').deleteprints()
      end,
      desc = 'Delete',
    },
    {
      '<leader>?t',
      function()
        require('debugprint.printtag_operations').toggle_comment_debugprints()
      end,
      desc = 'Toggle',
    },
    {
      '<leader>?v',
      function()
        require('debugprint').debugprint({
          variable = true,
        })
      end,
      desc = 'Variable (below)',
    },
    {
      '<leader>?V',
      function()
        require('debugprint').debugprint({
          variable = true,
          surround = true,
        })
      end,
      desc = 'Variable (surround)',
    },
    {
      '<leader>?p',
      function()
        require('debugprint').debugprint({})
      end,
      desc = 'Plain text',
    },
  },
  opts = {
    picker = 'telescope',
    picker_title = 'Debug Prints',
    highlight_lines = false,
    -- Turn off all keymaps by default for performance reasons (mapping overhead + can't lazy load)
    -- Also, I want to customize the descriptions
    keymaps = {
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
      insert = {
        plain = false,
        variable = false,
      },
      visual = {
        variable_below = false,
        variable_above = false,
      },
    },
  },
}
