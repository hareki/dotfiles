return {
  UI.catppuccin(function(palette)
    return {
      NoiceCmdlinePopupBorder = { fg = palette.blue },
      NoiceCmdlinePopupTitle = { fg = palette.blue },
      NoiceCmdlineIcon = { fg = palette.blue },
      NoiceConfirmBorder = { fg = palette.yellow },
      NoiceFormatConfirm = { bg = palette.surface1 },
      NoiceFormatConfirmDefault = { link = 'NoiceFormatConfirm' }, -- Make "Default" option have the same color as the others
    }
  end),

  {
    'hareki/noice.nvim',

    -- Prevent layout shifting (it hides the cmdline row)
    lazy = false,
    priority = Conf.priority.CHROME,

    opts = function()
      local trouble_ignored_parsers = { 'text' }

      return {
        format = {
          spinner = {
            name = 'circleFull',
          },
        },
        cmdline = {
          format = {
            search_down = { icon = Conf.icons.actions.SEARCH .. Conf.icons.navigation.DOWN },
            search_up = { icon = Conf.icons.actions.SEARCH .. Conf.icons.navigation.UP },
          },
        },
        messages = {
          -- Disable search count virtual text, use kevinhwang91/nvim-hlslens for more customization
          view_search = false,
        },
        presets = {
          lsp_doc_border = true,
          long_message_to_split = true,
        },
        views = {
          cmdline_popup = {
            zindex = 999,
          },
          confirm = {
            timeout = false,
            position = {
              row = '50%',
              col = '50%',
            },
            win_options = {
              winhighlight = {
                FloatTitle = 'WarningMsg',
                Question = 'Normal',
                MoreMsg = 'Normal',
              },
            },
          },
        },
        lsp = {
          progress = {
            -- noice only closes a progress item on its 'end' or when the client exits, so a server
            -- that never ends a token would leave its spinner up forever
            max_lifetime = 30 * 1000,
          },
          hover = {
            opts = { border = 'rounded' },
          },

          signature = {
            enabled = false,
          },
          override = {
            ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          },
        },
        routes = {
          {
            filter = {
              event = 'msg_show',
              any = {
                { find = '%d+L, %d+B' },
                { find = '; after #%d+' },
                { find = '; before #%d+' },
                { find = '%d+ lines? yanked' },
              },
            },
            opts = {
              skip = true,
            },
          },

          -- Ignore "No information available": a filetype can have several LSP clients
          {
            filter = {
              event = 'notify',
              find = '^No information available$',
            },
            opts = { skip = true },
          },

          -- Mute trouble's "parser missing" warning for allowlisted pseudo-languages; real misses
          -- still surface for nvim-treesitter's `ensure_installed`
          {
            filter = {
              event = 'notify',
              find = 'nvim%-treesitter parser missing',
              cond = function(message)
                local lang = message:content():match('parser missing `([^`]+)`')
                return lang ~= nil and vim.tbl_contains(trouble_ignored_parsers, lang)
              end,
            },
            opts = { skip = true },
          },

          -- Rewrite the native E21 and its Lua-wrapped E5108 (+ traceback) as one concise message;
          -- noice's default error route then displays it
          {
            filter = {
              error = true,
              cond = function(message)
                if message:content():find('E21:') then
                  message:set('Cannot make changes, readonly buffer', 'ErrorMsg')
                end
                return false -- Rewrite-only hook; fall through to the default error route
              end,
            },
            opts = {}, -- No view: this route never displays, it only mutates the message
          },
        },
      }
    end,

    config = function(_, opts)
      -- HACK: noice shows messages from before it was enabled, so clear them in the Lazy install UI
      if vim.bo.filetype == 'lazy' then
        vim.cmd.messages({ args = { 'clear' } })
      end

      local noice = require('noice')
      noice.setup(opts)
    end,
  },
}
