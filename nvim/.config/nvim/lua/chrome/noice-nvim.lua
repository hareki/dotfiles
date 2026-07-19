local dropbar_timer

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
      local popup = UI.layout.popup('md')
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
          bottom_search = false,
          command_palette = false,
          inc_rename = false,
          lsp_doc_border = true,
          long_message_to_split = true,
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
            opts = { border = 'rounded' },
          },

          signature = {
            enabled = false,
            --- @type NoiceViewOptions
            opts = {
              border = 'rounded',
              size = {
                width = popup.width,
                height = popup.height,
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
            opts = {
              skip = true,
            },
          },

          --  Ignore "No information available" since there could be multiple LSP clients for the same filetype
          {
            filter = {
              event = 'notify',
              find = '^No information available$',
            },
            opts = { skip = true },
          },

          -- Suppress the `client.stop` deprecation warning emitted by third-party
          -- plugins we don't control, like garbage-day.nvim.
          -- Only fork them when they actually break
          {
            filter = {
              find = 'client%.stop is deprecated',
            },
            opts = { skip = true },
          },

          -- Suppress trouble.nvim's cosmetic "parser missing" warning, but ONLY for
          -- the allowlisted pseudo-languages real missing parsers still
          -- surface so they can be added to nvim-treesitter's `ensure_installed`.
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

          -- Unify both "not modifiable" error variants into one concise message:
          --  - native       "E21: Cannot make changes, 'modifiable' is off"
          --  - Lua-wrapped  "E5108: ...: Vim:E21: ..." + stack traceback
          -- Both carry "E21:"; rewrite in place and let noice's default error route display it.
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

          -- Refresh dropbar when LSP progress completes
          {
            filter = {
              event = 'lsp',
              kind = 'progress',
              cond = function(message)
                local progress = message.opts.progress or {}
                if progress.kind == 'end' then
                  if not dropbar_timer then
                    dropbar_timer = vim.uv.new_timer()
                  end

                  if dropbar_timer then
                    dropbar_timer:stop()
                    dropbar_timer:start(
                      100,
                      0,
                      vim.schedule_wrap(function()
                        local dropbar_bar = require('dropbar.utils.bar')
                        dropbar_bar.exec('update')
                      end)
                    )
                  end
                end

                return false -- Don't match the condition for "opts"
              end,
            },
            opts = {}, -- Don't do anything, just use this as a hook to refresh dropbar
          },
        },
      }
    end,

    config = function(_, opts)
      -- HACK: noice shows messages from before it was enabled.
      -- This is not ideal when Lazy is installing plugins,
      -- so clear the messages in this case.
      if vim.bo.filetype == 'lazy' then
        vim.cmd.messages({ args = { 'clear' } })
      end

      local noice = require('noice')
      noice.setup(opts)
    end,
  },
}
