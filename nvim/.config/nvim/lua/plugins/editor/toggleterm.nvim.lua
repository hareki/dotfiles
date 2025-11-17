local default_name = 'terminal'

return {
  'hareki/toggleterm.nvim',
  cmd = { 'ToggleTerm', 'TermNew', 'TermSelect' },
  keys = {
    {
      '<A-t>',
      function()
        vim.cmd('101ToggleTerm direction=float name=" ToggleTerm "')
      end,
      desc = 'Toggle Floating Terminal',
      mode = { 'n', 't' },
    },
    {
      '<leader>tN',
      function()
        vim.cmd('TermNew direction=tab name=' .. default_name)
      end,
      desc = 'New Terminal Tab',
    },
  },
  opts = function()
    local float_configs = require('utils.ui').popup_config('lg')
    local default_highlights = {}
    for _, v in ipairs({
      'Normal',
      'Winbar',
      'WinbarNC',
      'SignColumn',
      'StatusLine',
      'EndOfBuffer',
      'FloatBorder',
    }) do
      default_highlights[v] = {
        link = v,
      }
    end

    return {
      highlights = default_highlights,
      direction = 'float',
      float_opts = {
        border = 'rounded',
        winblend = 0,
        row = float_configs.row,
        col = float_configs.col,
        width = float_configs.width,
        height = float_configs.height,
        title_pos = 'center',
      },
      on_open = function(term)
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, {
            noremap = true,
            silent = true,
            desc = desc,
            buffer = term.bufnr,
          })
        end

        map('n', '<leader>\\', function()
          vim.cmd('TermNew direction=horizontal name=' .. default_name)
        end, 'Split Terminal Right')

        map('n', '<leader>-', function()
          vim.cmd('TermNew direction=vertical name=' .. default_name)
        end, 'Split Terminal Below')

        map('n', '<leader>zn', function()
          vim.cmd('TermNew direction=current-window name=' .. default_name)
        end, 'New Terminal Window')

        if term.direction == 'float' then
          map('n', 'q', function()
            vim.api.nvim_win_close(term.window, true)
          end, 'Close Terminal')
        end
      end,
    }
  end,
}
