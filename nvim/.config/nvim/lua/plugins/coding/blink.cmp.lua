return {
  {
    'saghen/blink.compat',
    opts = {},
  },
  {
    'saghen/blink.cmp',
    -- Use a release tag to download pre-built binaries
    version = '*',
    dependencies = {
      -- 'rafamadriz/friendly-snippets',
      'windwp/nvim-autopairs',
      'dmitmel/cmp-cmdline-history',
      'f3fora/cmp-spell',
      'giuxtaposition/blink-cmp-copilot',
    },
    event = { 'InsertEnter', 'CmdLineEnter' },
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
      local copilot_kind_index = register_kind('Copilot')

      return {
        fuzzy = { implementation = 'prefer_rust_with_warning' },
        signature = { enabled = true, window = { border = 'rounded' } },
        appearance = {
          kind_icons = {
            History = '',
            Spell = '',
            Yanky = '󰅍',
            Copilot = '',
          },
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
          ghost_text = { enabled = true },
          trigger = {
            show_on_backspace = true,
            show_on_insert = true,
          },
          list = {
            selection = {
              preselect = true,
              -- https://github.com/Saghen/blink.cmp/blob/242fd1f31dd619ccb7fa7b5895e046ad675b411b/doc/configuration/keymap.md#super-tab
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
              padding = { 1, 1 },
              columns = { { 'label' }, { 'kind_icon' }, { 'kind' } },
              treesitter = { 'lsp' },
            },
          },
        },

        keymap = {
          preset = 'none',
          ['<Up>'] = {
            'select_prev',
            'fallback',
          },
          ['<Down>'] = {
            'select_next',
            'fallback',
          },
          ['<CR>'] = { 'accept', 'fallback' },
          ['<A-Space>'] = {
            function(cmp)
              cmp.show()
            end,
          },
          ['<Tab>'] = {
            function(cmp)
              if cmp.snippet_active() then
                return cmp.accept()
              else
                return cmp.select_and_accept()
              end
            end,
            'snippet_forward',
            'fallback',
          },
          ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
        },

        sources = {
          default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer', 'spell', 'copilot' },
          providers = {
            lazydev = {
              name = 'LazyDev',
              module = 'lazydev.integrations.blink',
              score_offset = 10,
            },

            cmdline = {
              min_keyword_length = cmdline_min_keyword_length(0),
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
                  -- item.kind_icon = '' -- overwrite if needed
                end
                return items
              end,
            },

            spell = {
              name = 'spell',
              module = 'blink.compat.source',
              max_items = 3,
              min_keyword_length = 4,
              score_offset = -5,
              transform_items = function(_, items)
                for _, item in ipairs(items) do
                  item.kind = spell_kind_index
                end
                return items
              end,
              opts = {
                keep_all_entries = false,
              },
            },

            copilot = {
              name = 'copilot',
              module = 'blink-cmp-copilot',
              async = true,
              max_items = 3,
              score_offset = 100,
              transform_items = function(_, items)
                for _, item in ipairs(items) do
                  item.kind = copilot_kind_index
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
