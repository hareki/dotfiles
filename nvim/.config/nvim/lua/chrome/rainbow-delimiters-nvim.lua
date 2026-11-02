return {
  UI.catppuccin(function(palette)
    return {
      RainbowDelimiterGreen = {
        fg = palette.pink, -- Avoid string color
      },
    }
  end),

  {
    'HiPhish/rainbow-delimiters.nvim',
    event = 'BufReadPost',

    init = function()
      vim.g.rainbow_delimiters = {
        -- Its first pass blocks the main thread: 2 s on a 1.3 MB package-lock.json. Sized in bytes
        -- since that cost follows delimiters, not lines (1.5 s on a dense 8k-line report)
        condition = function(bufnr)
          local line_count = vim.api.nvim_buf_line_count(bufnr)
          return vim.api.nvim_buf_get_offset(bufnr, line_count) <= 256 * 1024
        end,
      }
    end,
  },
}
