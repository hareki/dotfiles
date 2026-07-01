local DELAY = 350
local TIMEOUT_LEN = 250
local DELAY_O = DELAY - TIMEOUT_LEN

return {
  Catppuccin(function(palette)
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

      -- Append base group specs after any specs contributed by other plugins via WhichKey()
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
      -- Plugin-specific rules are defined in their respective plugin files via WhichKey()
      -- and prepended there, so these generic rules are appended to keep lower priority
      opts.icons.rules = vim.list_extend(opts.icons.rules or {}, {
        { pattern = 'terminal', icon = Icons.editor.terminal, color = 'green' },
        { pattern = 'plugin', icon = Icons.tools.plugin_manager, color = 'orange' },
        { pattern = 'help', icon = Icons.editor.help, color = 'blue' },
        { pattern = 'buffer', icon = Icons.editor.buffer, color = 'grey' },
        { pattern = 'undo', icon = Icons.actions.undo, color = 'purple' },
        { pattern = 'diagnostic', icon = Icons.editor.diagnostic, color = 'blue' },
        { pattern = 'highlight', icon = Icons.editor.highlight, color = 'blue' },
        { pattern = 'git', icon = Icons.git.git, color = 'red' },
        { pattern = 'window', icon = Icons.editor.window, color = 'blue' },
        { pattern = 'keymaps', icon = Icons.editor.keymaps, color = 'orange' },
        { pattern = 'scroll up', icon = Icons.navigation.scroll_up },
        { pattern = 'scroll down', icon = Icons.navigation.scroll_down },
        { pattern = 'code', icon = Icons.tools.code, color = 'red' },

        -- Generic ones, should have lower priority
        { pattern = 'typescript', icon = Icons.ft.typescript, color = 'blue' },
        { pattern = 'code actions', icon = Icons.actions.code_action, color = 'yellow' },
        { pattern = 'lsp', icon = Icons.tools.lsp, color = 'blue' },
        { pattern = 'register', icon = Icons.editor.register, color = 'yellow' },
        { pattern = 'tab', icon = Icons.misc.tab, color = 'blue' },
        { pattern = 'copilot', icon = Icons.kinds.Copilot, color = 'azure' },
        { pattern = 'rename', icon = Icons.actions.rename, color = 'yellow' },
        { pattern = 'grep', icon = Icons.actions.grep, color = 'green' },
        { pattern = 'find', icon = Icons.actions.find, color = 'blue' },
        { pattern = 'delete', icon = Icons.actions.delete, color = 'red' },
        { pattern = 'paste', icon = Icons.actions.paste, color = 'orange' },
        { pattern = 'peek', icon = Icons.actions.peek, color = 'yellow' },
        { pattern = 'reset', icon = Icons.actions.reset, color = 'red' },
        { pattern = 'prev', icon = Icons.navigation.prev },
        { pattern = 'backward', icon = Icons.navigation.prev },
        { pattern = 'first', icon = Icons.navigation.prev },
        { pattern = 'start', icon = Icons.navigation.prev },
        { pattern = 'around', icon = Icons.actions.around, color = 'purple' },
        { pattern = 'inside', icon = Icons.actions.inside, color = 'purple' },
        { pattern = 'next', icon = Icons.navigation.next },
        { pattern = 'forward', icon = Icons.navigation.next },
        { pattern = 'last', icon = Icons.navigation.next },
        { pattern = 'end', icon = Icons.navigation.next },
        { pattern = 'cut', icon = Icons.actions.cut, color = 'yellow' },
        { pattern = 'up', icon = Icons.navigation.up },
        { pattern = 'low', icon = Icons.navigation.down },
        { pattern = 'down', icon = Icons.navigation.down },
        { pattern = 'right', icon = Icons.navigation.right },
        { pattern = 'left', icon = Icons.navigation.left },
        { pattern = 'cycle', icon = Icons.navigation.cycle },
        { pattern = 'add', icon = Icons.actions.add, color = 'green' },
        { pattern = 'blame', icon = Icons.git.blame, color = 'green' },
        { pattern = 'url', icon = Icons.editor.url },
        { pattern = 'comment', icon = Icons.actions.comment },
        { pattern = 'prompt', icon = Icons.editor.prompt, color = 'blue' },
        { pattern = 'send file', icon = Icons.actions.send_file, color = 'cyan' },
        { pattern = 'newline', icon = Icons.actions.newline },
        { pattern = 'image', icon = Icons.editor.image, color = 'green' },
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
