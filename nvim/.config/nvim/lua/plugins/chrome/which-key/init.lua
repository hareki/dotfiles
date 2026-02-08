return {
  Catppuccin(function(palette)
    return {
      WhichKeyDesc = { fg = palette.text },
    }
  end),
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts_extend = { 'spec' },
    opts = function()
      local desc_override_specs = {}
      local keymap_registry = require('services.keymap_registry')
      for lhs, spec in pairs(keymap_registry.desc_overrides) do
        table.insert(desc_override_specs, { lhs, desc = spec.desc, mode = spec.mode })
      end

      return {
        preset = 'modern',
        win = {
          -- It's okay for the panel to overlap the cursor, don't push it down to the statusline
          no_overlap = false,
        },
        replace = {
          desc = {
            -- Add one extra space before the descriptions
            function(desc)
              if not desc then
                return ''
              end
              return ' ' .. desc
            end,
          },
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
        spec = vim.list_extend({
          { '<leader>c', group = 'Code', mode = { 'n', 'v' } },
          { '<leader>f', group = 'Find', mode = { 'n', 'v' } },
          { '<leader>fg', group = 'Git: Find' },
          { '<leader>d', group = 'Diffview' },
          { '<leader>h', group = 'Gitsigns', mode = { 'n', 'v' } },
          { '<leader>q', group = 'Quit', mode = { 'n', 'v' } },
          { '<leader>s', group = 'Search', mode = { 'n', 'v' } },
          { '<leader>t', group = 'Tab' },
          { '<leader>z', group = 'Terminal' },
          { '<leader>u', group = 'Notification' },
          { '<leader>?', group = 'Debug' },
          { '<leader>H', group = 'Harpoon File', mode = { 'n', 'v' } },
        }, desc_override_specs),

        icons = {
          group = '',
          rules = {
            -- Plugin > filetype > pattern
            -- Elements come first have higher priority when multiple patterns match
            { plugin = 'dropbar.nvim', icon = Icons.tools.breadcrumb, color = 'purple' },
            { plugin = 'auto-session', icon = Icons.tools.session, color = 'green' },
            { plugin = 'multicursors.nvim', icon = Icons.tools.multicursor, color = 'blue' },
            { plugin = 'nvim-tree.lua', icon = Icons.tools.tree, color = 'blue' },
            { plugin = 'eagle.nvim', icon = Icons.tools.eagle, color = 'yellow' },
            { plugin = 'debugprint.nvim', icon = Icons.tools.debug, color = 'red' },
            { pattern = 'yank', icon = Icons.actions.yank, color = 'yellow' },
            { pattern = 'mini.surround', icon = Icons.tools.surround, color = 'green' },
            { pattern = 'terminal', icon = Icons.editor.terminal, color = 'green' },
            { pattern = 'gitsigns', icon = Icons.git.sign, color = 'yellow' },

            { pattern = 'harpoon', icon = Icons.tools.harpoon, color = 'azure' },
            { pattern = 'diff', icon = Icons.git.diff, color = 'yellow' },
            { pattern = 'fold', icon = Icons.actions.fold, color = 'blue' },
            { pattern = 'help', icon = Icons.editor.help, color = 'blue' },
            { pattern = 'buffer', icon = Icons.editor.buffer, color = 'cyan' },
            { pattern = 'undo', icon = Icons.actions.undo, color = 'purple' },
            { pattern = 'diagnostic', icon = Icons.editor.diagnostic, color = 'blue' },
            { pattern = 'highlight', icon = Icons.editor.highlight, color = 'blue' },
            { pattern = 'git', icon = Icons.git.git, color = 'red' },
            { pattern = 'window', icon = Icons.editor.window, color = 'blue' },
            { pattern = 'keymaps', icon = Icons.editor.keymaps, color = 'orange' },
            { pattern = 'scroll up', icon = Icons.navigation.scroll_up },
            { pattern = 'scroll down', icon = Icons.navigation.scroll_down },

            -- Generic ones, should have lower priority
            { pattern = 'typescript', icon = Icons.ft.typescript, color = 'blue' },
            { pattern = 'mason', icon = Icons.tools.mason, color = 'yellow' },
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
            { pattern = 'first', icon = Icons.navigation.prev },
            { pattern = 'around', icon = Icons.actions.around, color = 'purple' },
            { pattern = 'inside', icon = Icons.actions.inside, color = 'purple' },
            { pattern = 'next', icon = Icons.navigation.next },
            { pattern = 'last', icon = Icons.navigation.next },
            { pattern = 'cut', icon = Icons.actions.cut, color = 'yellow' },
            { pattern = 'up', icon = Icons.navigation.up },
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
          },
        },
      }
    end,
    config = function(_, opts)
      local which_key = require('which-key')
      which_key.setup(opts)
      local which_key_preset = require('plugins.chrome.which-key.preset')
      which_key_preset.setup()
    end,
  },
}
