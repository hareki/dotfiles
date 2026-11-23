return {
  UI.catppuccin.integration('noice'),
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

    init = function()
      -- noice skips these messages, so nvim would send them per key and per mode change for nothing
      vim.opt.showcmd = false
      vim.opt.showmode = false
    end,

    opts = {
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
      presets = {
        lsp_doc_border = true,
        long_message_to_split = true,
      },
      views = {
        cmdline_popup = {
          zindex = Conf.zindex.CMDLINE,
        },
        confirm = {
          position = { row = '50%' },
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
          -- Without a cap, a server that never ends a token would leave its spinner up forever
          max_lifetime = 30 * 1000,
        },
        hover = {
          -- noice notifies "No information available" per client, even when another answered
          silent = true,
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

        -- Rewrite the native E21 and its Lua-wrapped E5108 (+ traceback) as one concise message
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
        },

        -- Render every other vim.notify message as markdown, as the Notifier renders its own
        {
          filter = {
            cond = function(message)
              -- Checked here, not as a filter key: noice walks a filter's keys in no set order
              if message.event == 'notify' then
                Notifier.adopt(message.opts)
              end
              return false -- Rewrite-only hook; fall through to the default notify route
            end,
          },
        },
      },
    },
    -- Other specs add the routes their plugins need (trouble.nvim's)
    opts_extend = { 'routes' },

    config = function(_, opts)
      -- HACK: noice shows messages from before it was enabled, so clear them in the Lazy install UI
      if vim.bo.filetype == 'lazy' then
        vim.cmd.messages('clear')
      end

      local noice = require('noice')
      noice.setup(opts)
    end,
  },
}
