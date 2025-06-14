return {
    {
        "numToStr/comment.nvim",
        dependencies = {
            "JoosepAlviste/nvim-ts-context-commentstring",
        },
        -- For some reason lazy.nvim can't detect the setup function for this one
        config = function()
            ---@diagnostic disable-next-line: missing-fields
            require("Comment").setup({
                pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
            })
        end,
    },
}
