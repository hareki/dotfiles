local cli_name = 'copilot'
return {
  require('utils.ui').catppuccin(function()
    return {
      SidekickDiffAdd = { link = 'DiffAdd' },
    }
  end),
  {
    'hareki/sidekick.nvim',
    event = 'VeryLazy',
    opts = function()
      local popup_config = require('utils.ui').popup_config
      local lg_popup_config = popup_config('lg')

      ---@class sidekick.Config
      return {
        nes = {
          mode = 'pending',
          debounce = 75,
          diff = {
            inline = 'chars',
          },
        },
        cli = {
          ---@class sidekick.win.Opts
          win = {
            layout = 'float',
            float = {
              width = lg_popup_config.width,
              height = lg_popup_config.height,
              -- Sidekick will take anything smaller or equal 1 as a percentage of the screen
              row = lg_popup_config.row + 0.1,
              col = lg_popup_config.col + 0.1,
              border = 'rounded',
            },
          },
          mux = {
            backend = 'tmux',
            enabled = true,
          },
        },
      }
    end,
    keys = {
      {
        '<Tab>',
        function()
          -- If there is a next edit, jump to it, otherwise apply it if any
          if not require('sidekick').nes_jump_or_apply() then
            return '<Tab>' -- fallback to normal tab
          end
        end,
        expr = true,
        desc = 'Goto/Apply Next Edit Suggestion',
      },
      {
        '<A-a>',
        function()
          require('sidekick.cli').toggle({ name = cli_name })
        end,
        desc = 'Sidekick Toggle',
        mode = { 'n', 't', 'i', 'x' },
      },
      {
        '<leader>at',
        function()
          require('sidekick.cli').send({
            msg = '{this}',
            filter = { name = cli_name },
          })
        end,
        mode = { 'x', 'n' },
        desc = 'Send This',
      },
      {
        '<leader>af',
        function()
          require('sidekick.cli').send({
            msg = '{file}',
            filter = { name = cli_name },
          })
        end,
        desc = 'Send File',
      },
      {
        '<leader>av',
        function()
          require('sidekick.cli').send({
            msg = '{selection}',
            filter = { name = cli_name },
          })
        end,
        mode = { 'x' },
        desc = 'Send Visual Selection',
      },
      {
        '<leader>ap',
        function()
          require('sidekick.cli').prompt()
        end,
        mode = { 'n', 'x' },
        desc = 'Select Prompt',
      },
      {
        '<A-Space>',
        function()
          if not require('sidekick.nes').have() then
            notifier.warn('No next edit suggestion found')
          end

          require('sidekick.nes').render_nes()
        end,
        desc = 'Render Next Edit Suggestions',
      },
    },
  },

  config = function(_, opts)
    require('sidekick').setup(opts)

    vim.api.nvim_create_autocmd('User', {
      pattern = 'SidekickNesDone',
      callback = function()
        require('sidekick.nes').render_nes()
      end,
    })
  end,
}
