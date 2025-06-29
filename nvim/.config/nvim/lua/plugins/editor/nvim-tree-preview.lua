return {
    'hareki/nvim-tree-preview.lua',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'herisetiawan00/image.nvim',
    },
    opts = {
        -- title_format = ' %s ', -- File name
        title_format = " " .. Constant.telescope.PREVIEW_TITLE .. " ",
        image_preview = {
            enable = true,
        },
    }
}
