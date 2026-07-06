local DELAY = 350
local TIMEOUT_LEN = 250
local DELAY_O = DELAY - TIMEOUT_LEN

return {
  UI.catppuccin(function(palette)
    return {
      WhichKeyDesc = { fg = palette.text },
    }
  end),

  {
    'hareki/which-key.nvim',
    event = 'VeryLazy',
    init = function()
      -- Lower than default (1000) to quickly trigger which-key
      vim.opt.timeoutlen = TIMEOUT_LEN
    end,

    opts = function(_, opts)
      local desc_override_specs = {}
      local keymap_registry = require('services.keymap-registry')
      for lhs, spec in pairs(keymap_registry.desc_overrides) do
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
        { '<leader>t', group = 'Tab' },
      })
      vim.list_extend(opts.spec, desc_override_specs)

      -- Plugin > filetype > pattern
      -- Elements come first have higher priority when multiple patterns match
      -- Plugin-specific rules are defined in their respective plugin files via UI.which_key()
      -- and prepended there, so these generic rules are appended to keep lower priority
      opts.icons.rules = vim.list_extend(opts.icons.rules or {}, {
        { pattern = 'terminal', icon = Conf.Icons.editor.TERMINAL, color = 'green' },
        { pattern = 'plugin', icon = Conf.Icons.tools.PLUGIN_MANAGER, color = 'orange' },
        { pattern = 'help', icon = Conf.Icons.editor.HELP, color = 'blue' },
        { pattern = 'buffer', icon = Conf.Icons.editor.BUFFER, color = 'grey' },
        { pattern = 'undo', icon = Conf.Icons.actions.UNDO, color = 'purple' },
        { pattern = 'diagnostic', icon = Conf.Icons.editor.DIAGNOSTIC, color = 'blue' },
        { pattern = 'highlight', icon = Conf.Icons.editor.HIGHLIGHT, color = 'blue' },
        { pattern = 'git', icon = Conf.Icons.git.GIT, color = 'red' },
        { pattern = 'window', icon = Conf.Icons.editor.WINDOW, color = 'blue' },
        { pattern = 'keymaps', icon = Conf.Icons.editor.KEYMAPS, color = 'orange' },
        { pattern = 'scroll up', icon = Conf.Icons.navigation.SCROLL_UP },
        { pattern = 'scroll down', icon = Conf.Icons.navigation.SCROLL_DOWN },
        { pattern = 'code', icon = Conf.Icons.tools.CODE, color = 'red' },

        -- Generic ones, should have lower priority
        { pattern = 'typescript', icon = Conf.Icons.ft.TYPESCRIPT, color = 'blue' },
        { pattern = 'code actions', icon = Conf.Icons.actions.CODE_ACTION, color = 'yellow' },
        { pattern = 'lsp', icon = Conf.Icons.tools.LSP, color = 'blue' },
        { pattern = 'register', icon = Conf.Icons.editor.REGISTER, color = 'yellow' },
        { pattern = 'tab', icon = Conf.Icons.misc.TAB, color = 'blue' },
        { pattern = 'rename', icon = Conf.Icons.actions.RENAME, color = 'yellow' },
        { pattern = 'grep', icon = Conf.Icons.actions.GREP, color = 'green' },
        { pattern = 'find', icon = Conf.Icons.actions.FIND, color = 'blue' },
        { pattern = 'delete', icon = Conf.Icons.actions.DELETE, color = 'red' },
        { pattern = 'paste', icon = Conf.Icons.actions.PASTE, color = 'orange' },
        { pattern = 'peek', icon = Conf.Icons.actions.PEEK, color = 'yellow' },
        { pattern = 'reset', icon = Conf.Icons.actions.RESET, color = 'red' },
        { pattern = 'prev', icon = Conf.Icons.navigation.PREV },
        { pattern = 'backward', icon = Conf.Icons.navigation.PREV },
        { pattern = 'first', icon = Conf.Icons.navigation.PREV },
        { pattern = 'start', icon = Conf.Icons.navigation.PREV },
        { pattern = 'around', icon = Conf.Icons.actions.AROUND, color = 'purple' },
        { pattern = 'inside', icon = Conf.Icons.actions.INSIDE, color = 'purple' },
        { pattern = 'next', icon = Conf.Icons.navigation.NEXT },
        { pattern = 'forward', icon = Conf.Icons.navigation.NEXT },
        { pattern = 'last', icon = Conf.Icons.navigation.NEXT },
        { pattern = 'end', icon = Conf.Icons.navigation.NEXT },
        { pattern = 'cut', icon = Conf.Icons.actions.CUT, color = 'yellow' },
        { pattern = 'up', icon = Conf.Icons.navigation.UP },
        { pattern = 'low', icon = Conf.Icons.navigation.DOWN },
        { pattern = 'down', icon = Conf.Icons.navigation.DOWN },
        { pattern = 'right', icon = Conf.Icons.navigation.RIGHT },
        { pattern = 'left', icon = Conf.Icons.navigation.LEFT },
        { pattern = 'cycle', icon = Conf.Icons.navigation.CYCLE },
        { pattern = 'add', icon = Conf.Icons.actions.ADD, color = 'green' },
        { pattern = 'blame', icon = Conf.Icons.git.BLAME, color = 'green' },
        { pattern = 'url', icon = Conf.Icons.editor.URL },
        { pattern = 'comment', icon = Conf.Icons.actions.COMMENT },
        { pattern = 'prompt', icon = Conf.Icons.editor.PROMPT, color = 'blue' },
        { pattern = 'send file', icon = Conf.Icons.actions.SEND_FILE, color = 'cyan' },
        { pattern = 'newline', icon = Conf.Icons.actions.NEWLINE },
        { pattern = 'image', icon = Conf.Icons.editor.IMAGE, color = 'green' },
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
