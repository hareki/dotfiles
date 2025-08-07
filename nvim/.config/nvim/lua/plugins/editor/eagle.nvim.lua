return {
  'soulis-1256/eagle.nvim',
  keys = {
    {
      'gh',
      function()
        require('eagle.keyboard_handler').render_keyboard_mode()
        local eagle_win = require('eagle.util').eagle_win
        if eagle_win and vim.api.nvim_win_is_valid(eagle_win) then
          vim.keymap.set({ 'n', 'x' }, 'q', function()
            vim.api.nvim_win_close(eagle_win, true)
          end, {
            buffer = vim.api.nvim_win_get_buf(eagle_win),
            desc = 'Eagle: Quit',
            silent = true,
          })
        end
      end,
      mode = { 'n', 'x' },
      desc = 'Hover',
      silent = true,
    },
  },
  opts = {
    keyboard_mode = true,
    mouse_mode = false,
    border = 'rounded',
        show_headers = false,
  },
}
