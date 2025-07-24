return {
  'hareki/nvim-tree-preview.lua',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'herisetiawan00/image.nvim',
  },
  opts = {
    -- title_format = ' %s ', -- File name
    title_format = ' ' .. require('configs.common').PREVIEW_TITLE .. ' ',
    zindex = 50, -- The defaul value makes vim.ui.input behind the preview window
    image_preview = {
      enable = true,
    },
  },
}
