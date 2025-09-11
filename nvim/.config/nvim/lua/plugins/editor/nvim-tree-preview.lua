return {
  'hareki/nvim-tree-preview.lua',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'herisetiawan00/image.nvim',
  },
  opts = function()
    return {
      -- title_format = ' %s ', -- File name
      title_format = require('configs.common').preview_title.others,
      zindex = 50, -- The defaul value makes vim.ui.input behind the preview window
      image_preview = {
        enable = true,
      },
    }
  end,
}
