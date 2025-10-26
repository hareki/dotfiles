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
    local popup_config = require('utils.ui').popup_config('sm')

    -- Open telescope find_files when Neovim starts on a directory
    vim.api.nvim_create_autocmd('VimEnter', {
      once = true,
      callback = function(data)
        vim.schedule(function()
          -- Only act if the argument is a directory and there is no session for auto-session to load
          if
            vim.fn.isdirectory(data.file) == 0
            or vim.v.this_session and vim.v.this_session ~= ''
          then
            return
          end

          vim.cmd.cd(data.file) -- Set cwd to that dir
          local buf = vim.api.nvim_get_current_buf()

          -- Leftover buffer from opening a directory (netrw)
          vim.bo[buf].buflisted = false
          vim.bo[buf].bufhidden = 'wipe'
          vim.opt_local.number = false
          vim.opt_local.relativenumber = false

          vim.schedule(function()
            require('snacks')
            require('plugins.ui.snacks.picker_query_persister').files()
          end)
        end)
      end,
    })

    return {
      suppressed_dirs = { '~/', '~/Downloads', '/' },
      ---@type SessionLens
      session_lens = {
        picker = 'snacks',
        load_on_setup = false,
        picker_opts = {
          preview = false,
          layout = {
            width = popup_config.width,
            max_width = popup_config.width,
            height = popup_config.height,
            max_height = popup_config.height,
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
