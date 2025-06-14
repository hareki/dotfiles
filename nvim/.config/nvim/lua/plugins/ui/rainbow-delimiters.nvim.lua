return {
    {
        "hiphish/rainbow-delimiters.nvim",
        config = function()
            local palette = Util.get_palette()
            Util.highlights({
                -- Setting different color from "String" highlight group to avoid confusion
                RainbowDelimiterGreen = { fg = palette.rosewater },
            })
        end,
    },
}
