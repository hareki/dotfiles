return {
    "catgoose/nvim-colorizer.lua",
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
    opts = {
        user_default_options = {
            names = false,
            css = true
        }
    }
}
