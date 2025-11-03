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
          local is_directory = vim.fn.isdirectory(data.file) == 1
          local has_session = vim.v.this_session and vim.v.this_session ~= ''

          if not is_directory or has_session then
            return
          end

          -- Set cwd to that dir
          vim.cmd.cd(data.file)

          -- AutoSession disables autosave when argv cwd mismatches; flip it back after cd
          local auto_session_config = require('auto-session.config')
          if auto_session_config.auto_save == false then
            auto_session_config.auto_save = true
          end

          local buf = vim.api.nvim_get_current_buf()

          -- Leftover buffer from opening a directory (netrw)
          vim.bo[buf].buflisted = false
          vim.bo[buf].bufhidden = 'wipe'
          vim.opt_local.number = false
          vim.opt_local.relativenumber = false

          vim.schedule(function()
            require('snacks')
            Snacks.picker.files()
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
