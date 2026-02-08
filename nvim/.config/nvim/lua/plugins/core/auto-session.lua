return {
  'rmagatti/auto-session',
  lazy = false,
  keys = {
    {
      '<leader>fs',
      function()
        vim.cmd.AutoSession({ args = { 'search' } })
      end,
      desc = 'Find Session',
    },
  },

  init = function()
    -- https://github.com/rmagatti/auto-session?tab=readme-ov-file#recommended-sessionoptions-config
    vim.opt.sessionoptions = 'blank,buffers,curdir,folds,help,tabpages,winsize,winpos'

    -- Open snacks files picker when Neovim starts on a directory
    vim.api.nvim_create_autocmd('VimEnter', {
      once = true,
      callback = function(data)
        vim.schedule(function()
          local stat = vim.uv.fs_stat(data.file)
          local is_directory = stat and stat.type == 'directory'
          local has_session = vim.v.this_session and vim.v.this_session ~= ''

          if not is_directory or has_session then
            return
          end

          -- Set cwd to that dir
          vim.cmd({ cmd = 'cd', args = { data.file } })

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
            local lazy = require('lazy')
            lazy.load({ plugins = { 'snacks.nvim' } })
            Snacks.picker.files()
          end)
        end)
      end,
    })
  end,

  opts = function()
    local ui = require('utils.ui')
    local popup_config = ui.popup_config('sm')

    ---@module "auto-session"
    ---@type AutoSession.Config
    return {
      suppressed_dirs = { '~/', '~/Downloads', '/' },
      post_restore_cmds = {
        function()
          vim.schedule(function()
            pcall(vim.cmd.ColorizerAttachToBuffer)
          end)
        end,
      },

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
          alternate_session = { 'n', 's' }, -- Swapping between the current session and the last one
          copy_session = { 'n', 'y' },
        },
      },
    }
  end,
}
