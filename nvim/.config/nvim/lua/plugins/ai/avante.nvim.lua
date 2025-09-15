return {
  require('utils.ui').catppuccin(function(palette)
    return {
      AvantePromptInput = { bg = palette.base },
      AvantePromptInputBorder = { link = 'FloatBorder' },
      AvantePopupHint = { bg = palette.base, fg = palette.yellow },
      AvantePromptInputPrefix = { fg = palette.blue },
      AvantePromptEditPrefix = { fg = palette.blue },

      AvanteTitle = { fg = palette.base, bg = palette.yellow },
      AvanteSubtitle = { fg = palette.base, bg = palette.blue },
      AvanteReversedTitle = { bg = palette.base, fg = palette.yellow },
      AvanteReversedSubtitle = { bg = palette.base, fg = palette.blue },
    }
  end),
  {
    'hareki/avante.nvim',
    build = 'make',

    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',

      'nvim-telescope/telescope.nvim',
      'folke/snacks.nvim', -- for input provider
      'nvim-tree/nvim-web-devicons',
      'zbirenbaum/copilot.lua', -- for copilot provider
    },
    keys = {
      {
        '<leader>aa',
        function()
          require('avante.api').ask()
        end,
        mode = { 'n', 'v' },
        desc = 'Avante: Ask',
      },
      {
        '<leader>ac',
        function()
          require('avante.api').ask({ ask = false })
        end,
        mode = { 'n', 'v' },
        desc = 'Avante: Chat',
      },
      {
        '<leader>ae',
        function()
          require('avante.api').edit()
        end,
        mode = { 'v' },
        desc = 'Avante: Edit',
      },
      {
        '<leader>am',
        function()
          require('avante.api').select_model()
        end,
        desc = 'Avante: Select Model',
      },

      {
        '<leader>ah',
        function()
          require('avante.api').select_history()
        end,
        desc = 'Avante: Select History',
      },
      {
        '<leader>as',
        function()
          require('avante.api').stop()
        end,
        desc = 'Avante: Stop',
      },
      --   {
      --     '<leader>a+',
      --     function()
      --       local tree_ext = require('avante.extensions.nvim_tree')
      --       tree_ext.add_file()
      --     end,
      --     desc = '(Avante) Select file in NvimTree',
      --     ft = 'NvimTree',
      --   },
      --   {
      --     '<leader>a-',
      --     function()
      --       local tree_ext = require('avante.extensions.nvim_tree')
      --       tree_ext.remove_file()
      --     end,
      --     desc = '(Avante) Deselect file in NvimTree',
      --     ft = 'NvimTree',
      --   },
    },
    opts = function()
      local ui_utils = require('utils.ui')
      local icons = require('configs.icons')

      local sidebar_width = ui_utils.computed_size(require('configs.size').side_panel.md)
      local screen_w = ui_utils.screen_size()
      local sidebar_width_percent = math.floor((sidebar_width / screen_w) * 100)

      local input_width, input_height = ui_utils.computed_size('input')
      local prompt_prefix = icons.input.prompt_prefix

      ---@module 'avante'
      ---@type avante.Config
      return {
        instructions_file = '.github/copilot-instructions.md',
        provider = 'copilot',
        providers = {
          copilot = {
            model = 'gpt-5',
          },
        },

        selector = {
          provider = 'telescope',
          -- Options override for custom providers
          provider_opts = {},
        },
        input = {
          provider = 'snacks',
          provider_opts = {
            -- title = '',
            -- icon = '',
          },
        },
        windows = {
          position = 'right',
          width = sidebar_width_percent,
          spinner = {
            editing = icons.misc.spinner_frames,
            generating = icons.misc.spinner_frames,
          },
          input = {
            prefix = prompt_prefix,
            height = 10,
          },
          edit = {
            prefix = prompt_prefix,
            border = 'rounded',
            height = input_height,
            width = input_width,
          },
        },
        behaviour = {
          auto_suggestions = false,
          auto_set_keymaps = false,
        },
        selection = {
          enabled = false,
        },
        mappings = {
          sidebar = {
            close_from_input = {
              normal = 'q',
            },
          },
        },
      }
    end,
  },
}
