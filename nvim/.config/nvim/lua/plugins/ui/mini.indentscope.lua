return {
    "echasnovski/mini.indentscope",
    version = false,
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
    opts = function()
        Util.highlights({
            MiniIndentscopeSymbol = { fg = Util.get_palette().blue },
        })
        return {
            -- symbol = "│",
            symbol = "┃",
            options = { try_as_border = true },
            draw = {
                delay = 100,
                -- animation = require('mini.indentscope').gen_animation.none()
            },
        }
    end,
    init = function()
        vim.api.nvim_create_autocmd("FileType", {
            pattern = {
                "Trouble",
                "alpha",
                "dashboard",
                "fzf",
                "help",
                "lazy",
                "mason",
                "neo-tree",
                "NvimTree",
                "notify",
                "snacks_notif",
                "snacks_terminal",
                "snacks_win",
                "toggleterm",
                "trouble",
                "dropbar_menu",
            },
            callback = function()
                vim.b.miniindentscope_disable = true
            end,
        })
    end,
}
