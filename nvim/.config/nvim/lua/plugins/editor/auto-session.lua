return {
  'rmagatti/auto-session',
  lazy = false,
  keys = {
    {
      '<leader>fs',
      '<CMD>AutoSession search<CR>',
      desc = 'Find Session',
    },
  },

  ---enables autocomplete for opts
  ---@module "auto-session"
  ---@type AutoSession.Config
  opts = function()
    local layout_config = require('utils.ui').telescope_layout('sm')
    return {
      suppressed_dirs = { '~/', '~/Downloads', '/' },
      -- For some reason auto-session always drop me in insert mode (even without terminal buffers)
      post_restore_cmds = {
        function()
          vim.schedule(function()
            vim.cmd('stopinsert')
          end)
        end,
      },
      ---@type SessionLens
      session_lens = {
        picker = 'telescope',
        load_on_setup = false,
        picker_opts = {
          layout_config = {
            width = layout_config.width,
            height = layout_config.height,
          },
        },

        ---@type SessionLensMappings
        mappings = {
          delete_session = { 'n', 'x' },
          alternate_session = { 'n', 's' }, -- swapping between the current session and the last one
          copy_session = { 'n', 'y' },
        },
      },
    }
  end,
}
