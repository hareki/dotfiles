return {
  require('utils.ui').catppuccin(function(palette)
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
      for lhs, desc in pairs(require('plugins.editor.which-key.preset').desc_overrides) do
        table.insert(desc_override_specs, { lhs, desc = desc })
      end

      return {
        preset = 'modern',
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
          scroll_down = '<S-PageDown>', -- binding to scroll down inside the popup
          scroll_up = '<S-PageUp>', -- binding to scroll up inside the popup
        },
        spec = vim.list_extend({
          { '<leader>c', group = 'Code' },
          { '<leader>f', group = 'Find' },
          { '<leader>fg', group = 'Git: Find' },
          { '<leader>d', group = 'Diffview' },
          { '<leader>h', group = 'Hunk' },
          { '<leader>q', group = 'Quit' },
          { '<leader>s', group = 'Search' },
          { '<leader>t', group = 'Tab' },
          { '<leader>u', group = 'Notification' },
          { '<leader>?', group = 'Debug' },
        }, desc_override_specs),

        icons = {
          rules = {
            -- Plugin > filetype > pattern
            -- Elements come first have higher priority when multiple patterns match
            { plugin = 'yanky.nvim', pattern = 'yank', icon = '', color = 'yellow' },
            { plugin = 'harpoon', icon = '󰛢', color = 'azure' },
            { plugin = 'dropbar.nvim', icon = '', color = 'purple' },
            { plugin = 'multicursors.nvim', icon = '' },
            { plugin = 'nvim-tree.lua', icon = ' ', color = 'blue' },
            { plugin = 'eagle.nvim', icon = '󱗆', color = 'yellow' },
            { plugin = 'debugprint.nvim', icon = '󰃤', color = 'red' },

            { pattern = 'diff', icon = '', color = 'yellow' },
            { pattern = 'help', icon = '󰋗', color = 'blue' },
            { pattern = 'hunk', icon = '', color = 'yellow' },
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
            { pattern = 'lsp', icon = ' ', color = 'blue' },
            { pattern = 'rename', icon = '󰑕', color = 'yellow' },
            { pattern = 'grep', icon = ' ', color = 'green' },
            { pattern = 'find', icon = ' ', color = 'green' },
            { pattern = 'find', icon = ' ', color = 'blue' },
            { pattern = 'delete', icon = '󰗨', color = 'red' },
            { pattern = 'paste', icon = '', color = 'orange' },
            { pattern = 'peek', icon = '󰈈', color = 'yellow' },
            { pattern = 'reset', icon = '󰑓', color = 'red' },
            { pattern = 'prev', icon = '󰒮', color = 'grey' },
            { pattern = 'first', icon = '󰒮', color = 'grey' },
            { pattern = 'around', icon = '󰭶', color = 'purple' },
            { pattern = 'inside', icon = '󰹗', color = 'purple' },
            { pattern = 'next', icon = '󰒭', color = 'grey' },
            { pattern = 'last', icon = '󰒭', color = 'grey' },
            { pattern = 'cut', icon = '', color = 'yellow' },
            { pattern = 'up', icon = '' },
            { pattern = 'down', icon = '' },
            { pattern = 'right', icon = '' },
            { pattern = 'left', icon = '' },
            { pattern = 'cycle', icon = '' },
            { pattern = 'add', icon = '', color = 'green' },
            { pattern = 'blame', icon = ' ', color = 'green' },
            { pattern = 'url', icon = ' ' },
          },
        },
      }
    end,
    config = function(_, opts)
      require('which-key').setup(opts)
      require('plugins.editor.which-key.preset').setup()
    end,
  },
}
