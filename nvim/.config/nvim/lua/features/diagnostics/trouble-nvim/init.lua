-- Pseudo-languages trouble looks a parser up for, which none will ever exist for
local PARSERLESS_LANGUAGES = { 'text' }

return {
  UI.catppuccin.integration('lsp_trouble'),
  UI.catppuccin(function(palette)
    return {
      TroubleNormal = { link = 'NormalFloat' },
      TroublePreview = { link = 'Search' },
      TroubleIconDirectory = { link = 'Directory' },
      TroubleSnacksIcon = { fg = palette[Conf.icons.colors.SNACKS] },
      TroubleSnacksCount = { fg = palette.lavender },
      -- Paths read as they do in the picker the list came from
      TroubleSnacksDirname = { link = 'SnacksPickerDir' },
      TroubleSnacksBasename = { link = 'SnacksPickerFile' },
    }
  end, 'trouble.nvim'),

  {
    'noice.nvim',
    optional = true,
    opts = {
      routes = {
        -- Mute trouble's "parser missing" warning for the languages above; a real miss still
        -- surfaces, as a parser to add to the table in core/nvim-treesitter/utils.lua
        {
          filter = {
            event = 'notify',
            find = 'nvim%-treesitter parser missing',
            cond = function(message)
              local lang = message:content():match('parser missing `([^`]+)`')
              return vim.list_contains(PARSERLESS_LANGUAGES, lang)
            end,
          },
          opts = { skip = true },
        },
      },
    },
  },

  {
    'snacks.nvim',
    opts = {
      picker = {
        actions = {
          -- Send a picker's results to Trouble, which keeps them on screen
          snacks_to_trouble = function(picker)
            local snacks_source = require('trouble.sources.snacks')
            snacks_source.open(picker)
          end,
        },
        win = {
          input = {
            keys = {
              ['<C-t>'] = { 'snacks_to_trouble', mode = { 'i', 'n' } },
            },
          },
          preview = {
            keys = {
              ['<C-t>'] = { 'snacks_to_trouble', mode = { 'i', 'n' } },
            },
          },
        },
      },
    },
  },

  {
    'hareki/trouble.nvim',
    cmd = { 'Trouble' },
    keys = {
      {
        '[q',
        function()
          local utils = require('features.diagnostics.trouble-nvim.utils')
          utils.jump('prev')
        end,
        desc = 'Previous Trouble/Quickfix Item',
      },
      {
        ']q',
        function()
          local utils = require('features.diagnostics.trouble-nvim.utils')
          utils.jump('next')
        end,
        desc = 'Next Trouble/Quickfix Item',
      },
    },

    opts = function()
      local utils = require('features.diagnostics.trouble-nvim.utils')
      local side_preview = UI.layout.side_preview()
      local panel_cols = UI.layout.side_panel_width('md')

      return {
        auto_refresh = false,
        win = { position = 'right', size = panel_cols },

        formatters = {
          dirname = utils.format_dirname,
        },

        -- The title row moves to the winbar, so it stays in view as the list scrolls
        modes = {
          snacks = {
            groups = {
              { 'filename', format = '{file_icon} {dirname}{basename} {count}' },
            },
            win = { wo = { winbar = utils.SNACKS_WINBAR } },
          },
          snacks_files = {
            groups = {},
            format = '{file_icon} {dirname}{basename}',
            win = { wo = { winbar = utils.SNACKS_WINBAR } },
          },
        },

        icons = {
          folder_closed = Conf.icons.file_tree.FOLDER,
          folder_open = Conf.icons.file_tree.FOLDER_OPEN,
        },

        preview = {
          type = 'float',
          relative = 'win',
          border = 'rounded',
          -- Fractional row: trouble resolves it against the parent on every open, so centering
          -- survives resizes; a negative col counts from the panel's right edge, hence the shift
          position = { 0.5, side_preview.col - panel_cols },
          size = {
            width = side_preview.width,
            height = side_preview.height,
          },
          zindex = Conf.zindex.TROUBLE_PREVIEW,

          reuse_loaded_buf = false,
          notify_on_toggle = false,
          close_on_non_item = true,
        },

        keys = {
          ['<Tab>'] = {
            action = utils.toggle_focus,
            desc = 'Toggle Focus Between List and Preview',
          },
          B = 'toggle_preview',
        },
      }
    end,
  },
}
