local copilot_max_items = 2

return {
  Catppuccin(function(palette)
    return {
      BlinkCmpKindRenderMD = { fg = palette.text },
      BlinkCmpLabelMatch = { fg = palette.blue },
      BlinkCmpLabel = { fg = palette.text },
      BlinkCmpKindVariable = { link = '@variable' },
    }
  end),
  {
    'saghen/blink.compat',
    opts = {},
  },
  {
    'fang2hou/blink-copilot',
    opts = function()
      return {
        max_completions = copilot_max_items,
        max_attempts = copilot_max_items + 1,
        kind_name = 'Copilot',
        kind_icon = ' ',
        kind_hl = 'BlinkCmpKindCopilot',
        debounce = 200,
        auto_refresh = {
          backward = true,
          forward = true,
        },
      }
    end,
  },
  {
    'saghen/blink.cmp',
    version = '*', -- Use a release tag to download pre-built binaries
    event = { 'InsertEnter', 'CmdLineEnter' },
    dependencies = {
      'windwp/nvim-autopairs',

      'dmitmel/cmp-cmdline-history',
      'f3fora/cmp-spell',

      'zbirenbaum/copilot.lua',
      'fang2hou/blink-copilot',
    },
    opts = function()
      local function register_kind(name)
        local cmp_types = require('blink.cmp.types')
        local CompletionItemKind = cmp_types.CompletionItemKind
        local kind_index = CompletionItemKind[name]

        if not kind_index then
          kind_index = #CompletionItemKind + 1
          CompletionItemKind[kind_index] = name
          CompletionItemKind[name] = kind_index
        end

        return kind_index
      end

      ---@param length number | nil
      local function cmdline_min_keyword_length(length)
        return function(ctx)
          -- When typing a command, only show when the keyword is 3 characters or longer
          if ctx.mode == 'cmdline' and string.find(ctx.line, ' ') == nil then
            return length or 3
          end
          return 0
        end
      end

      local history_kind_index = register_kind('History')
      local spell_kind_index = register_kind('Spell')
      local render_markdown_index = register_kind('RenderMD')
      local icons = require('configs.icons')

      return {
        fuzzy = { implementation = 'prefer_rust_with_warning' },
        signature = { enabled = true, window = { border = 'rounded' } },
        appearance = {
          kind_icons = icons.kinds,
        },

        cmdline = {
          enabled = true,
          keymap = {
            preset = 'inherit',
            ['<Esc>'] = {
              function(cmp)
                if cmp.is_menu_visible() then
                  cmp.hide()
                  return true
                end
              end,
              -- 'fallback' won't cut it because of this bug in neovim
              -- https://github.com/neovim/neovim/issues/21585
              function()
                -- Feed <C-c> to cancel the command line instead
                local keys = vim.api.nvim_replace_termcodes('<C-c>', true, false, true)
                vim.api.nvim_feedkeys(keys, 'n', false)
                return true
              end,
            },
          },
          sources = { 'buffer', 'cmdline', 'cmdline_history' },
          completion = {
            menu = { auto_show = false },
            ghost_text = {
              enabled = false,
            },
            list = {
              selection = {
                preselect = true,
                auto_insert = false,
              },
            },
          },
        },

        completion = {
          accept = { auto_brackets = { enabled = false } },
          ghost_text = { enabled = true },
          trigger = {
            prefetch_on_insert = false,
            show_on_backspace = true,
            show_on_backspace_after_insert_enter = true,
            show_on_insert = true,
            show_on_keyword = true,
            show_in_snippet = true,
          },
          list = {
            selection = {
              preselect = true,
              -- Super-tab config: https://github.com/Saghen/blink.cmp/blob/242fd1f31dd619ccb7fa7b5895e046ad675b411b/doc/configuration/keymap.md#super-tab
              -- preselect = function()
              --   return not require('blink.cmp').snippet_active({ direction = 1 })
              -- end,
              auto_insert = false,
            },
          },
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 200,
            window = { border = 'rounded' },
          },
          menu = {
            border = 'rounded',
            scrollbar = false,
            draw = {
              padding = { 1, 0 }, -- For some reason it already has 1 padding on the right
              columns = {
                { 'kind_icon' },
                { 'label', 'label_description', gap = 1 },
              },
              components = {
                label = {
                  width = { fill = false, max = 20 },
                },
                label_description = {
                  width = { max = 20 },
                },
              },
            },
          },
        },

        keymap = {
          preset = 'none',
          ['<CR>'] = { 'accept', 'fallback' },
          ['<Tab>'] = { 'snippet_forward', 'fallback' },
          ['<S-Tab>'] = { 'snippet_backward', 'fallback' },

          ['<Up>'] = {
            'select_prev',
            'fallback',
          },
          ['<Down>'] = {
            'select_next',
            'fallback',
          },

          ['<PageUp>'] = {
            function(cmp)
              if cmp.is_documentation_visible() then
                cmp.scroll_documentation_up(4)
              end
              return true
            end,
          },
          ['<PageDown>'] = {
            function(cmp)
              if cmp.is_documentation_visible() then
                cmp.scroll_documentation_down(4)
              end
              return true
            end,
          },
          ['<Space>'] = {
            function(cmp)
              -- Force reset the completion context when typing too fast
              vim.defer_fn(function()
                cmp.hide()
              end, 20)
            end,
            'fallback',
          },

          ['<A-Space>'] = {
            function(cmp)
              if cmp.is_menu_visible() then
                return cmp.show({ providers = { 'copilot' } })
              else
                return cmp.show()
              end
            end,
            'fallback',
          },
        },

        sources = {
          default = { 'copilot', 'lsp', 'path', 'snippets', 'buffer', 'spell' },
          per_filetype = {
            markdown = { inherit_defaults = true, 'markdown' },
            lua = { inherit_defaults = true, 'lazydev' },
          },
          providers = {
            lsp = {
              opts = { tailwind_color_icon = '' },
            },

            lazydev = {
              name = 'LazyDev',
              module = 'lazydev.integrations.blink',
              max_items = 6,
              score_offset = 10,
            },

            buffer = {
              max_items = 3,
              score_offset = -10,
              should_show_items = function()
                local filetype = vim.api.nvim_get_option_value('filetype', { buf = 0 })
                local is_ignored_filetype = vim.list_contains({ '', 'NvimTree' }, filetype) -- NvimTree live_filter has a blank filetype
                return not is_ignored_filetype
              end,
            },

            cmdline = {
              min_keyword_length = cmdline_min_keyword_length(0),
              max_items = 6,
            },

            cmdline_history = {
              name = 'cmdline_history',
              module = 'blink.compat.source',
              max_items = 6,
              min_keyword_length = cmdline_min_keyword_length(0),

              transform_items = function(_, items)
                for _, item in ipairs(items) do
                  item.kind = history_kind_index
                  item.kind_hl = 'BlinkCmpKindKeyword'
                  -- item.kind_icon = '' -- Overwrite if needed
                end
                return items
              end,
            },

            spell = {
              name = 'spell',
              module = 'blink.compat.source',
              max_items = 3,
              min_keyword_length = 4,
              score_offset = -20,
              opts = { keep_all_entries = false },

              transform_items = function(_, items)
                for _, item in ipairs(items) do
                  item.kind = spell_kind_index

                  -- Remove spaces from all text fields
                  local fields = { 'label', 'filterText', 'sortText', 'insertText' }
                  for _, field in ipairs(fields) do
                    if item[field] then
                      item[field] = item[field]:gsub(' ', '')
                    end
                  end

                  if item.textEdit and item.textEdit.newText then
                    item.textEdit.newText = item.textEdit.newText:gsub(' ', '')
                  end
                end
                return items
              end,
            },

            copilot = {
              name = 'copilot',
              module = 'blink-copilot',
              max_items = copilot_max_items,
              score_offset = -7,
              async = true,
            },

            markdown = {
              name = 'markdown',
              module = 'render-markdown.integ.blink',
              max_items = 3,
              transform_items = function(_, items)
                for _, item in ipairs(items) do
                  item.kind = render_markdown_index
                  item.kind_hl = 'BlinkCmpKindRenderMD'
                end
                return items
              end,
            },
          },
        },
      }
    end,
  },
}
