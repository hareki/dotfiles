local copilot_max_items = 2
local ripgrep_min_keyword_length = 4

return {
  Catppuccin(function(palette)
    return {
      BlinkCmpKindRenderMD = { fg = palette.text },
      BlinkCmpKindHistory = { fg = palette.mauve },
      BlinkCmpLabelMatch = { fg = palette.blue },
      BlinkCmpKindRipgrepGit = { fg = palette.red },
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
      local icons = require('configs.icons')

      return {
        max_completions = copilot_max_items,
        max_attempts = copilot_max_items + 1,
        kind_name = 'Copilot',
        kind_icon = icons.kinds.Copilot,
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

      'zbirenbaum/copilot.lua',
      'fang2hou/blink-copilot',

      'xieyonn/blink-cmp-dat-word',
      'mikavilpas/blink-ripgrep.nvim',
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

      local config_dir = vim.fn.stdpath('config')
      local google_10k_words = config_dir .. '/words/google-10000-english-usa-no-swears-long.txt'
      local built_in_words = '/usr/share/dict/words'

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
            max_height = 15,
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
          default = { 'copilot', 'lsp', 'path', 'snippets', 'buffer', 'datword', 'ripgrep' },
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
              name = 'CmdlineHistory',
              module = 'blink.compat.source',
              max_items = 6,
              min_keyword_length = cmdline_min_keyword_length(0),

              transform_items = function(_, items)
                for _, item in ipairs(items) do
                  item.kind = history_kind_index
                end

                return items
              end,
            },

            datword = {
              name = 'Datword',
              module = 'blink-cmp-dat-word',
              max_items = 3,
              min_keyword_length = 4,
              score_offset = -20,
              opts = {
                paths = { google_10k_words, built_in_words },
                spellsuggest = true,
              },

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
              name = 'Copilot',
              module = 'blink-copilot',
              max_items = copilot_max_items,
              async = true,
              -- Wrap around the menu items to quickly access the suggestion items while prevent items shifting
              score_offset = -100,
              -- should_show_items = function(ctx)
              --   -- Only show items if 'copilot' is the sole provider to avoid distraction
              --   return ctx.providers[1] == 'copilot' and #ctx.providers == 1
              -- end,
            },

            ripgrep = {
              name = 'Ripgrep',
              module = 'blink-ripgrep',
              max_items = 3,
              min_keyword_length = ripgrep_min_keyword_length,
              score_offset = -10,
              ---@module "blink-ripgrep"
              ---@type blink-ripgrep.Options
              opts = {
                prefix_min_len = ripgrep_min_keyword_length,
                backend = {
                  use = 'gitgrep',
                },
                gitgrep = {
                  additional_gitgrep_options = {},
                },
              },
            },

            markdown = {
              name = 'RenderMarkdown',
              module = 'render-markdown.integ.blink',
              max_items = 3,
              transform_items = function(_, items)
                for _, item in ipairs(items) do
                  item.kind = render_markdown_index
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
