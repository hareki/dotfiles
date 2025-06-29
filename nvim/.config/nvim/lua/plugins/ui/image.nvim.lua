return {
    -- TODO: waiting for this PR to be merged: https://github.com/3rd/image.nvim/pull/299
    'herisetiawan00/image.nvim',
    build = false, -- so that it doesn't build the rock https://github.com/3rd/image.nvim/issues/91#issuecomment-2453430239
    opts = {
        backend = 'kitty',
        processor = "magick_cli",
    }
}
