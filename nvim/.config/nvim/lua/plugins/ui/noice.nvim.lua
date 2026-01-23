return {
  Catppuccin(function(palette)
    return {
      NoiceCmdlinePopupBorder = { fg = palette.blue },
      NoiceCmdlinePopupTitle = { fg = palette.blue },
      NoiceCmdlineIcon = { fg = palette.blue },
      NoiceConfirmBorder = { fg = palette.yellow },
      NoiceFormatConfirmDefault = { link = 'NoiceFormatConfirm' }, -- Make "Default" option have the same color as the others
    }
  end),
  {
    'folke/noice.nvim',

    -- Prevent layout shifting (it hides the cmdline row)
    lazy = false,
    priority = 500,

    opts = {
      format = {
        spinner = {
          name = 'circleFull',
        },
      },
      views = {
        cmdline_popup = {
          zindex = 999, -- Ensure cmdline popup is always on top
        },
        confirm = {
          backend = 'popup',
          relative = 'editor',
          timeout = false,
          position = {
            row = '50%',
            col = '50%',
          },
          win_options = {
            winhighlight = {
              Normal = 'NoiceConfirm',
              FloatBorder = 'NoiceConfirmBorder',
              FloatTitle = 'WarningMsg',
              Question = 'Normal',
              MoreMsg = 'Normal',
            },
          },
        },
      },
      lsp = {
        hover = {
          opts = {
            border = 'rounded',
          },
        },
        signature = {
          enabled = false,
          ---@type NoiceViewOptions
          opts = {
            border = 'rounded',
            size = {
              row = 10,
              col = 60,
            },
          },
        },
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
          ['cmp.entry.get_documentation'] = true,
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
            },
          },
          -- view = 'mini',
          opts = {
            skip = true,
          },
        },
        {
          -- Ignore null-ls messages since it's just for cspell
          filter = {
            event = 'lsp',
            kind = 'progress',
            cond = function(message)
              local client = vim.tbl_get(message.opts, 'progress', 'client')
              return client == 'null-ls'
            end,
          },
          opts = { skip = true },
        },

        --  Ignore "No information available" since there could be multiple LSP clients for the same filetype
        {
          filter = {
            event = 'notify',
            find = '^No information available$',
          },
          opts = { skip = true },
        },
        {
          filter = {
            event = 'lsp',
            kind = 'progress',
            cond = function(message)
              local progress = message.opts.progress or {}
              if progress.kind == 'end' then
                local dropbar_utils = require('dropbar.utils.bar')
                dropbar_utils.exec('update')
              end

              return false -- Don't match the condition for "opts"
            end,
          },
          opts = {}, -- Don't do anything, just use this as a hook to refresh dropbar
        },
      },
      presets = {
        bottom_search = false,
        command_palette = false,
        inc_rename = false,
        lsp_doc_border = true,
        long_message_to_split = true,
      },
    },
    config = function(_, opts)
      -- HACK: noice shows messages from before it was enabled.
      -- This is not ideal when Lazy is installing plugins,
      -- so clear the messages in this case.
      if vim.o.filetype == 'lazy' then
        vim.cmd.messages({ args = { 'clear' } })
      end
      local noice = require('noice')
      noice.setup(opts)
    end,
  },
}
