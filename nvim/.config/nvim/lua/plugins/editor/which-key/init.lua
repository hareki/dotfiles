return {
  Catppuccin(function(palette)
    return {
      WhichKeyDesc = { fg = palette.text },
      -- WhichKey = { fg = palette.red },
    }
  end),
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts_extend = { 'spec' },
    opts = function()
      local desc_override_specs = {}
      local which_key_preset = require('plugins.editor.which-key.preset')
      for lhs, spec in pairs(which_key_preset.desc_overrides) do
        table.insert(desc_override_specs, { lhs, desc = spec.desc, mode = spec.mode })
      end

      local icons = require('configs.icons')

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
            { plugin = 'yanky.nvim', pattern = 'yank', icon = '', color = 'yellow' },
            { plugin = 'dropbar.nvim', icon = '', color = 'purple' },
            { plugin = 'auto-session', icon = '󰆓', color = 'green' },
            { plugin = 'multicursors.nvim', icon = '' },
            { plugin = 'nvim-tree.lua', icon = ' ', color = 'blue' },
            { plugin = 'eagle.nvim', icon = '󱗆', color = 'yellow' },
            { plugin = 'debugprint.nvim', icon = '󰃤', color = 'red' },
            { pattern = 'mini.surround', icon = '󰗅 ', color = 'green' },
            { pattern = 'terminal', icon = ' ', color = 'green' },
            { pattern = 'gitsigns', icon = '', color = 'yellow' },

            { pattern = 'harpoon', icon = '󰛢', color = 'azure' },
            { pattern = 'diff', icon = '', color = 'yellow' },
            { pattern = 'fold', icon = '', color = 'blue' },
            { pattern = 'help', icon = '󰋗', color = 'blue' },
            { pattern = 'buffer', icon = ' ', color = 'cyan' },
            { pattern = 'undo', icon = '', color = 'purple' },
            { pattern = 'diagnostic', icon = '󱖫 ', color = 'blue' },
            { pattern = 'highlight', icon = '', color = 'blue' },
            { pattern = 'git', icon = '󰊢', color = 'red' },
            { pattern = 'window', icon = ' ', color = 'blue' },
            { pattern = 'keymaps', icon = ' ', color = 'orange' },
            { pattern = 'scroll up', icon = '󱕑 ' },
            { pattern = 'scroll down', icon = '󱕐 ' },

            -- Generic ones, should have lower priority
            { pattern = 'typescript', icon = ' ', color = 'blue' },
            { pattern = 'mason', icon = ' ', color = 'yellow' },
            { pattern = 'code actions', icon = '', color = 'yellow' },
            { pattern = 'lsp', icon = '  ', color = 'blue' },
            { pattern = 'register', icon = '', color = 'yellow' },
            { pattern = 'tab', icon = icons.misc.tab, color = 'blue' },
            { pattern = 'copilot', icon = ' ', color = 'azure' },
            { pattern = 'rename', icon = '󰑕', color = 'yellow' },
            { pattern = 'grep', icon = ' ', color = 'green' },
            { pattern = 'find', icon = ' ', color = 'green' },
            { pattern = 'find', icon = ' ', color = 'blue' },
            { pattern = 'delete', icon = '󰗨', color = 'red' },
            { pattern = 'paste', icon = '', color = 'orange' },
            { pattern = 'peek', icon = '󰈈', color = 'yellow' },
            { pattern = 'reset', icon = '󰑓', color = 'red' },
            { pattern = 'prev', icon = '󰒮' },
            { pattern = 'first', icon = '󰒮' },
            { pattern = 'around', icon = '󰭶', color = 'purple' },
            { pattern = 'inside', icon = '󰹗', color = 'purple' },
            { pattern = 'next', icon = '󰒭' },
            { pattern = 'last', icon = '󰒭' },
            { pattern = 'cut', icon = '', color = 'yellow' },
            { pattern = 'up', icon = '' },
            { pattern = 'down', icon = '' },
            { pattern = 'right', icon = '' },
            { pattern = 'left', icon = '' },
            { pattern = 'cycle', icon = '' },
            { pattern = 'add', icon = '', color = 'green' },
            { pattern = 'blame', icon = ' ', color = 'green' },
            { pattern = 'url', icon = ' ' },
            { pattern = 'comment', icon = '󰿠' },
            { pattern = 'prompt', icon = '󰍩', color = 'blue' },
            { pattern = 'send file', icon = '󰈪', color = 'cyan' },
          },
        },
      }
    end,
    config = function(_, opts)
      local which_key = require('which-key')
      which_key.setup(opts)
      local which_key_preset = require('plugins.editor.which-key.preset')
      which_key_preset.setup()
    end,
  },
}
