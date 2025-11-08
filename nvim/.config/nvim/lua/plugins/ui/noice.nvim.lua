return {
  require('utils.ui').catppuccin(function(palette)
    return {
      NoiceCmdlinePopupBorder = { fg = palette.blue },
      NoiceCmdlinePopupTitle = { fg = palette.blue },
      NoiceCmdlineIcon = { fg = palette.blue },
    }
  end),
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
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
      },
      lsp = {
        hover = {
          opts = {
            border = 'rounded',
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
                require('dropbar.utils.bar').exec('update')
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
      -- HACK: noice shows messages from before it was enabled,
      -- but this is not ideal when Lazy is installing plugins,
      -- so clear the messages in this case.
      if vim.o.filetype == 'lazy' then
        vim.cmd([[messages clear]])
      end
      require('noice').setup(opts)
    end,
  },
}
