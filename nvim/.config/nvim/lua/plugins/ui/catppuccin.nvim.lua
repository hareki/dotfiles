return {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
        styles = {                   -- Handles the styles of general hi groups (see `:h highlight-args`):
            comments = { "italic" }, -- Change the style of comments
            conditionals = { "italic" },
            loops = {},
            functions = {},
            keywords = {},
            strings = {},
            variables = {},
            numbers = {},
            booleans = {},
            properties = {},
            types = {},
            operators = {},
            -- miscs = {}, -- Uncomment to turn off hard-coded styles
        },
        integrations = {
            cmp = true,
            dashboard = true,
            nvimtree = true,
            flash = true,
            fzf = true,
            grug_far = true,
            gitsigns = true,
            indent_blankline = { enabled = true },
            lsp_trouble = true,
            mason = true,
            markdown = true,
            mini = true,
            native_lsp = {
                enabled = true,
                underlines = {
                    errors = { "undercurl" },
                    hints = { "undercurl" },
                    warnings = { "undercurl" },
                    information = { "undercurl" },
                },
            },
            neotest = true,
            noice = true,
            notify = true,
            semantic_tokens = true,
            snacks = true,
            telescope = true,
            treesitter = true,
            treesitter_context = true,
            which_key = true,
        },
    },
    init = function()
        vim.cmd.colorscheme("catppuccin-mocha")
    end,
}
