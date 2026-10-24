return {
  UI.which_key({
    rules = { plugin = 'auto-session', icon = Conf.icons.tools.SESSION, color = 'green' },
  }),

  {
    'hareki/auto-session',
    lazy = false,
    priority = Conf.priority.CORE,
    init = function()
      vim.opt.sessionoptions = 'buffers,curdir,folds'

      -- Registered here, ahead of the VimLeavePre auto-session sets up when it loads, so the
      -- codediff tabs are gone before its exit save inspects the windows and buffers
      vim.api.nvim_create_autocmd('VimLeavePre', {
        group = vim.api.nvim_create_augroup('core.auto-session.close-codediff-tabs', {
          clear = true,
        }),
        callback = function()
          local codediff_utils = require('features.git.codediff-nvim.utils')
          codediff_utils.close_tabs()
        end,
      })
    end,

    keys = {
      {
        '<leader>fs',
        '<cmd>AutoSession search<cr>',
        desc = 'Find Session',
      },
    },

    opts = function()
      -- Function-valued so the session picker follows terminal resizes
      local popup_config = UI.layout.picker_fn('sm')

      --- @module "auto-session"
      --- @type AutoSession.Config
      return {
        suppressed_dirs = { '~/', '~/Downloads', '/' },
        no_restore_cmds = {
          --- @param is_startup boolean?
          function(is_startup)
            -- Started on a directory that has no session yet: adopt it as the cwd
            local dir = vim.api.nvim_buf_get_name(0)
            if not is_startup or vim.fn.isdirectory(dir) == 0 then
              return
            end

            vim.cmd.cd({ args = { dir } })

            -- AutoSession turns autosave off when the directory argument isn't the cwd yet
            local auto_session_config = require('auto-session.config')
            auto_session_config.auto_save = true

            -- Leftover buffer from opening a directory
            local buf = vim.api.nvim_get_current_buf()
            vim.bo[buf].buflisted = false
            vim.bo[buf].bufhidden = 'wipe'
            vim.opt_local.number = false
            vim.opt_local.relativenumber = false

            vim.schedule(function()
              local api = require('nvim-tree.api')
              api.tree.open()
            end)
          end,
        },
        pre_save_cmds = {
          function()
            -- Only preserve visible buffers (buffers that are attached to windows, in any tabpage);
            -- Snacks.bufdelete only goes through the listed ones
            Snacks.bufdelete({
              filter = function(buf)
                return not vim.bo[buf].modified and #vim.fn.win_findbuf(buf) == 0
              end,
            })
          end,
        },

        --- @type SessionLens
        session_lens = {
          picker = 'snacks',
          load_on_setup = false,
          picker_opts = {
            preview = false,
            layout = {
              width = popup_config.width,
              height = popup_config.height,
            },
          },

          --- @type SessionLensMappings
          mappings = {
            delete_session = { 'n', 'x' },
            alternate_session = { 'n', 's' }, -- Swapping between the current session and the last one
            copy_session = { 'n', 'y' },
          },
        },
      }
    end,
  },
}
