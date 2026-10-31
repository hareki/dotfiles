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

    opts = {
      preset = 'modern',
      delay = function(ctx)
        return ctx.mode == 'o' and DELAY_O or DELAY
      end,
      win = {
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
        scroll_down = '<S-PageDown>',
        scroll_up = '<S-PageUp>',
      },
      icons = {
        group = '',
      },

      spec = {
        { '<leader>c', group = 'Code', mode = { 'n', 'v' } },
        { '<leader>f', group = 'Find', mode = { 'n', 'v' } },
        { '<leader>fg', group = 'Git: Find' },
        { '<leader>q', group = 'Quit', mode = { 'n', 'v' } },
        { '<leader>s', group = 'Search', mode = { 'n', 'v' } },
      },

      -- <auto> skips single-letter builtins; plugins needing one use UI.which_key({ triggers })
      triggers = {
        { '<auto>', mode = 'nxso' },
      },
    },

    config = function(_, opts)
      -- Earlier rules win, so these generic ones go after every tier's UI.which_key() rules
      vim.list_extend(opts.icons.rules, {
        { pattern = 'terminal', icon = Conf.icons.editor.TERMINAL, color = 'green' },
        { pattern = 'plugin', icon = Conf.icons.tools.PLUGIN_MANAGER, color = 'orange' },
        { pattern = 'help', icon = Conf.icons.editor.HELP, color = 'blue' },
        { pattern = 'buffer', icon = Conf.icons.editor.BUFFER, color = 'grey' },
        { pattern = 'undo', icon = Conf.icons.actions.UNDO, color = 'purple' },
        { pattern = 'diagnostic', icon = Conf.icons.editor.DIAGNOSTIC, color = 'blue' },
        { pattern = 'highlight', icon = Conf.icons.editor.HIGHLIGHT, color = 'blue' },
        -- Frontier-anchored so it stops matching 'digit', which leaves 'lazygit' to its own rule
        { pattern = '%f[%a]git', icon = Conf.icons.git.GIT, color = 'red' },
        { pattern = 'lazygit', icon = Conf.icons.git.GIT, color = 'red' },
        { pattern = 'window', icon = Conf.icons.editor.WINDOW, color = 'blue' },
        { pattern = 'keymaps', icon = Conf.icons.editor.KEYMAPS, color = 'orange' },
        { pattern = 'scroll up', icon = Conf.icons.navigation.SCROLL_UP },
        { pattern = 'scroll down', icon = Conf.icons.navigation.SCROLL_DOWN },
        { pattern = 'code actions', icon = Conf.icons.actions.CODE_ACTION, color = 'yellow' },
        { pattern = 'code', icon = Conf.icons.tools.CODE, color = 'red' },

        -- Generic ones, should have lower priority
        { pattern = 'typescript', icon = Conf.icons.ft.TYPESCRIPT, color = 'blue' },
        { pattern = 'mark', icon = Conf.icons.tools.MARK, color = 'yellow' },
        { pattern = 'lsp', icon = Conf.icons.tools.LSP, color = 'yellow' },
        { pattern = 'register', icon = Conf.icons.editor.REGISTER, color = 'yellow' },
        { pattern = 'tab', icon = Conf.icons.misc.TAB, color = 'blue' },
        { pattern = 'rename', icon = Conf.icons.actions.RENAME, color = 'yellow' },
        { pattern = 'find', icon = Conf.icons.actions.FIND, color = 'blue' },
        { pattern = 'delete', icon = Conf.icons.actions.DELETE, color = 'red' },
        { pattern = 'paste', icon = Conf.icons.actions.PASTE, color = 'orange' },
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
        -- Whole-word 'up', not 'uppercase' or 'group' (which would pre-empt 'cycle' below)
        { pattern = '%f[%a]up%f[%A]', icon = Conf.icons.navigation.UP },
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
        { pattern = 'newline', icon = Conf.icons.actions.NEWLINE },
        { pattern = 'image', icon = Conf.icons.editor.IMAGE, color = 'green' },
      })

      local which_key = require('which-key')
      which_key.setup(opts)
      local which_key_preset = require('chrome.which-key-nvim.preset')
      which_key_preset.setup()
    end,
  },
}
