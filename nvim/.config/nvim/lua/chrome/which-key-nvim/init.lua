local DELAY = 350
local TIMEOUT_LEN = 250
local DELAY_O = DELAY - TIMEOUT_LEN

return {
  UI.catppuccin(function(palette)
    return {
      WhichKeyDesc = { fg = palette.text },
    }
  end, 'which-key.nvim'),

  {
    'hareki/which-key.nvim',
    event = 'VeryLazy',
    init = function()
      -- Lower than default (1000) to quickly trigger which-key
      vim.opt.timeoutlen = TIMEOUT_LEN
    end,

    opts = function(_, opts)
      local desc_override_specs = {}
      local keymap_registry = require('config.keymap-registry')
      for lhs, spec in pairs(keymap_registry.DESC_OVERRIDES) do
        table.insert(desc_override_specs, { lhs, desc = spec.desc, mode = spec.mode })
      end

      -- Merge in the base scalar config. The list fields (spec, icons.rules) are appended
      -- separately below, since tbl_deep_extend index-merges arrays instead of concatenating.
      opts = vim.tbl_deep_extend('force', opts, {
        preset = 'modern',
        delay = function(ctx)
          return ctx.mode == 'o' and DELAY_O or DELAY
        end,
        win = {
          no_overlap = true,
          padding = { 0, 4 },
        },
        plugins = {
          -- Define the presets ourselves to unify the letter case
          presets = {
            operators = false,
            motions = false,
            text_objects = false,
            windows = false,
            nav = false,
            z = false,
            g = false,
          },
        },
        keys = {
          scroll_down = '<S-PageDown>', -- Binding to scroll down inside the popup
          scroll_up = '<S-PageUp>', -- Binding to scroll up inside the popup
        },
        icons = {
          group = '',
        },
      })

      -- Append base group specs after any specs contributed by other plugins via UI.which_key()
      opts.spec = vim.list_extend(opts.spec or {}, {
        { '<leader>c', group = 'Code', mode = { 'n', 'v' } },
        { '<leader>f', group = 'Find', mode = { 'n', 'v' } },
        { '<leader>fg', group = 'Git: Find' },
        { '<leader>q', group = 'Quit', mode = { 'n', 'v' } },
        { '<leader>s', group = 'Search', mode = { 'n', 'v' } },
      })
      vim.list_extend(opts.spec, desc_override_specs)

      -- Plugin > filetype > pattern
      -- Elements come first have higher priority when multiple patterns match
      -- Plugin-specific rules are defined in their respective plugin files via UI.which_key()
      -- and prepended there, so these generic rules are appended to keep lower priority
      opts.icons.rules = vim.list_extend(opts.icons.rules or {}, {
        { pattern = 'terminal', icon = Conf.icons.editor.TERMINAL, color = 'green' },
        { pattern = 'plugin', icon = Conf.icons.tools.PLUGIN_MANAGER, color = 'orange' },
        { pattern = 'help', icon = Conf.icons.editor.HELP, color = 'blue' },
        { pattern = 'buffer', icon = Conf.icons.editor.BUFFER, color = 'grey' },
        { pattern = 'undo', icon = Conf.icons.actions.UNDO, color = 'purple' },
        { pattern = 'diagnostic', icon = Conf.icons.editor.DIAGNOSTIC, color = 'blue' },
        { pattern = 'highlight', icon = Conf.icons.editor.HIGHLIGHT, color = 'blue' },
        { pattern = 'git', icon = Conf.icons.git.GIT, color = 'red' },
        { pattern = 'window', icon = Conf.icons.editor.WINDOW, color = 'blue' },
        { pattern = 'keymaps', icon = Conf.icons.editor.KEYMAPS, color = 'orange' },
        { pattern = 'scroll up', icon = Conf.icons.navigation.SCROLL_UP },
        { pattern = 'scroll down', icon = Conf.icons.navigation.SCROLL_DOWN },
        { pattern = 'code', icon = Conf.icons.tools.CODE, color = 'red' },

        -- Generic ones, should have lower priority
        { pattern = 'typescript', icon = Conf.icons.ft.TYPESCRIPT, color = 'blue' },
        { pattern = 'code actions', icon = Conf.icons.actions.CODE_ACTION, color = 'yellow' },
        { pattern = 'lsp', icon = Conf.icons.tools.LSP, color = 'blue' },
        { pattern = 'register', icon = Conf.icons.editor.REGISTER, color = 'yellow' },
        { pattern = 'tab', icon = Conf.icons.misc.TAB, color = 'blue' },
        { pattern = 'rename', icon = Conf.icons.actions.RENAME, color = 'yellow' },
        { pattern = 'grep', icon = Conf.icons.actions.GREP, color = 'green' },
        { pattern = 'find', icon = Conf.icons.actions.FIND, color = 'blue' },
        { pattern = 'delete', icon = Conf.icons.actions.DELETE, color = 'red' },
        { pattern = 'paste', icon = Conf.icons.actions.PASTE, color = 'orange' },
        { pattern = 'peek', icon = Conf.icons.actions.PEEK, color = 'yellow' },
        { pattern = 'reset', icon = Conf.icons.actions.RESET, color = 'red' },
        { pattern = 'prev', icon = Conf.icons.navigation.PREV },
        { pattern = 'backward', icon = Conf.icons.navigation.PREV },
        { pattern = 'first', icon = Conf.icons.navigation.PREV },
        { pattern = 'start', icon = Conf.icons.navigation.PREV },
        { pattern = 'around', icon = Conf.icons.actions.AROUND, color = 'purple' },
        { pattern = 'inside', icon = Conf.icons.actions.INSIDE, color = 'purple' },
        { pattern = 'next', icon = Conf.icons.navigation.NEXT },
        { pattern = 'forward', icon = Conf.icons.navigation.NEXT },
        { pattern = 'last', icon = Conf.icons.navigation.NEXT },
        { pattern = 'end', icon = Conf.icons.navigation.NEXT },
        { pattern = 'cut', icon = Conf.icons.actions.CUT, color = 'yellow' },
        { pattern = 'up', icon = Conf.icons.navigation.UP },
        { pattern = 'low', icon = Conf.icons.navigation.DOWN },
        { pattern = 'down', icon = Conf.icons.navigation.DOWN },
        { pattern = 'right', icon = Conf.icons.navigation.RIGHT },
        { pattern = 'left', icon = Conf.icons.navigation.LEFT },
        { pattern = 'cycle', icon = Conf.icons.navigation.CYCLE },
        { pattern = 'add', icon = Conf.icons.actions.ADD, color = 'green' },
        { pattern = 'blame', icon = Conf.icons.git.BLAME, color = 'green' },
        { pattern = 'url', icon = Conf.icons.editor.URL },
        { pattern = 'comment', icon = Conf.icons.actions.COMMENT },
        { pattern = 'prompt', icon = Conf.icons.editor.PROMPT, color = 'blue' },
        { pattern = 'send file', icon = Conf.icons.actions.SEND_FILE, color = 'cyan' },
        { pattern = 'newline', icon = Conf.icons.actions.NEWLINE },
        { pattern = 'image', icon = Conf.icons.editor.IMAGE, color = 'green' },
      })

      return opts
    end,

    config = function(_, opts)
      local which_key = require('which-key')
      which_key.setup(opts)
      local which_key_preset = require('chrome.which-key-nvim.preset')
      which_key_preset.setup()
    end,
  },
}
