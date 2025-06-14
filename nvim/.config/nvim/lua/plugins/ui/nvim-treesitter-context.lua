return {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
    opts = function()
        Util.highlights({
            TreesitterContextBottom = { bold = false, italic = false },
            TreesitterContext = { link = "DocumentHighlight" },
            TreesitterContextLineNumber = { link = "DocumentHighlight" },
        })

        local tsc = require("treesitter-context")
        Snacks.toggle({
            name = "Treesitter Context",
            get = tsc.enabled,
            set = function(state)
                if state then
                    tsc.enable()
                else
                    tsc.disable()
                end
            end,
        }):map("<leader>ut")
        return { mode = "cursor", max_lines = 4 }
    end,
}
