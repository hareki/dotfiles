return {
    {
        "kevinhwang91/nvim-ufo",
        dependencies = { "kevinhwang91/promise-async" },
        config = function()
            local map = vim.keymap.set
            local opt = vim.opt
            local ufo = require("ufo")

            map("n", "zR", require("ufo").openAllFolds, { desc = "Open all folds" })
            map("n", "zM", require("ufo").closeAllFolds, { desc = "Close all folds" })
            map("n", "zK", function()
                local winid = require("ufo").peekFoldedLinesUnderCursor()
                if not winid then
                    vim.lsp.buf.hover()
                end
            end, { desc = "Peek fold" })

            opt.foldcolumn = "1"
            opt.foldlevel = 99
            opt.foldlevelstart = 99
            opt.foldenable = true

            -- https://github.com/kevinhwang91/nvim-ufo/blob/1ebb9ea3507f3a40ce8b0489fb259ab32b1b5877/README.md?plain=1#L97
            ufo.setup({
                provider_selector = function()
                    return { "treesitter", "indent" }
                end,
            })
        end,
    },
}
