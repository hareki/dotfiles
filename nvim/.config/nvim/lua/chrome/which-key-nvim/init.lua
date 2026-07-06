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
      local keymap_registry = require('services.keymap_registry')
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
        { pattern = 'terminal', icon = Conf.Icons.editor.terminal, color = 'green' },
        { pattern = 'plugin', icon = Conf.Icons.tools.plugin_manager, color = 'orange' },
        { pattern = 'help', icon = Conf.Icons.editor.help, color = 'blue' },
        { pattern = 'buffer', icon = Conf.Icons.editor.buffer, color = 'grey' },
        { pattern = 'undo', icon = Conf.Icons.actions.undo, color = 'purple' },
        { pattern = 'diagnostic', icon = Conf.Icons.editor.diagnostic, color = 'blue' },
        { pattern = 'highlight', icon = Conf.Icons.editor.highlight, color = 'blue' },
        { pattern = 'git', icon = Conf.Icons.git.git, color = 'red' },
        { pattern = 'window', icon = Conf.Icons.editor.window, color = 'blue' },
        { pattern = 'keymaps', icon = Conf.Icons.editor.keymaps, color = 'orange' },
        { pattern = 'scroll up', icon = Conf.Icons.navigation.scroll_up },
        { pattern = 'scroll down', icon = Conf.Icons.navigation.scroll_down },
        { pattern = 'code', icon = Conf.Icons.tools.code, color = 'red' },

        -- Generic ones, should have lower priority
        { pattern = 'typescript', icon = Conf.Icons.ft.typescript, color = 'blue' },
        { pattern = 'code actions', icon = Conf.Icons.actions.code_action, color = 'yellow' },
        { pattern = 'lsp', icon = Conf.Icons.tools.lsp, color = 'blue' },
        { pattern = 'register', icon = Conf.Icons.editor.register, color = 'yellow' },
        { pattern = 'tab', icon = Conf.Icons.misc.tab, color = 'blue' },
        { pattern = 'rename', icon = Conf.Icons.actions.rename, color = 'yellow' },
        { pattern = 'grep', icon = Conf.Icons.actions.grep, color = 'green' },
        { pattern = 'find', icon = Conf.Icons.actions.find, color = 'blue' },
        { pattern = 'delete', icon = Conf.Icons.actions.delete, color = 'red' },
        { pattern = 'paste', icon = Conf.Icons.actions.paste, color = 'orange' },
        { pattern = 'peek', icon = Conf.Icons.actions.peek, color = 'yellow' },
        { pattern = 'reset', icon = Conf.Icons.actions.reset, color = 'red' },
        { pattern = 'prev', icon = Conf.Icons.navigation.prev },
        { pattern = 'backward', icon = Conf.Icons.navigation.prev },
        { pattern = 'first', icon = Conf.Icons.navigation.prev },
        { pattern = 'start', icon = Conf.Icons.navigation.prev },
        { pattern = 'around', icon = Conf.Icons.actions.around, color = 'purple' },
        { pattern = 'inside', icon = Conf.Icons.actions.inside, color = 'purple' },
        { pattern = 'next', icon = Conf.Icons.navigation.next },
        { pattern = 'forward', icon = Conf.Icons.navigation.next },
        { pattern = 'last', icon = Conf.Icons.navigation.next },
        { pattern = 'end', icon = Conf.Icons.navigation.next },
        { pattern = 'cut', icon = Conf.Icons.actions.cut, color = 'yellow' },
        { pattern = 'up', icon = Conf.Icons.navigation.up },
        { pattern = 'low', icon = Conf.Icons.navigation.down },
        { pattern = 'down', icon = Conf.Icons.navigation.down },
        { pattern = 'right', icon = Conf.Icons.navigation.right },
        { pattern = 'left', icon = Conf.Icons.navigation.left },
        { pattern = 'cycle', icon = Conf.Icons.navigation.cycle },
        { pattern = 'add', icon = Conf.Icons.actions.add, color = 'green' },
        { pattern = 'blame', icon = Conf.Icons.git.blame, color = 'green' },
        { pattern = 'url', icon = Conf.Icons.editor.url },
        { pattern = 'comment', icon = Conf.Icons.actions.comment },
        { pattern = 'prompt', icon = Conf.Icons.editor.prompt, color = 'blue' },
        { pattern = 'send file', icon = Conf.Icons.actions.send_file, color = 'cyan' },
        { pattern = 'newline', icon = Conf.Icons.actions.newline },
        { pattern = 'image', icon = Conf.Icons.editor.image, color = 'green' },
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
