return {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    init = function()
        vim.g.lualine_laststatus = vim.o.laststatus
        if vim.fn.argc(-1) > 0 then
            -- set an empty statusline till lualine loads
            vim.o.statusline = " "
        else
            -- hide the statusline on the starter page
            vim.o.laststatus = 0
        end
    end,
    opts = function()
        -- PERF: we don't need this lualine require madness 🤷
        local lualine_require = require("lualine_require")
        lualine_require.require = require

        local icons = Constant.icons

        vim.o.laststatus = vim.g.lualine_laststatus

        local harpoon_indicators = {}
        local harpoon_active_indicators = {}

        for i = 1, 6 do
            table.insert(harpoon_indicators, tostring(i))
            table.insert(harpoon_active_indicators, "[" .. tostring(i) .. "]")
        end

        local opts = {
            options = {
                theme = "auto",
                globalstatus = vim.o.laststatus == 3,
                disabled_filetypes = { statusline = { "dashboard", "netrw" } },

                section_separators = { left = "", right = "" },
                component_separators = { left = "", right = "" },
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = {
                    {
                        "branch",
                        fmt = Util.git.format_branch_name,
                    },
                    {
                        "diff",
                        symbols = {
                            added = icons.git.added,
                            modified = icons.git.modified,
                            removed = icons.git.removed,
                        },
                        source = function()
                            local gitsigns = vim.b.gitsigns_status_dict
                            if gitsigns then
                                return {
                                    added = gitsigns.added,
                                    modified = gitsigns.changed,
                                    removed = gitsigns.removed,
                                }
                            end
                        end,
                    },
                },

                lualine_c = {
                    {
                        function()
                            local repo = Util.git.get_repo_name()
                            return repo and ("󱉭 " .. repo) or "󱉭"
                        end,
                    },
                    {
                        "harpoon2",
                        icon = "󰀱",
                        indicators = harpoon_indicators,
                        active_indicators = harpoon_active_indicators,
                    },
                },
                lualine_x = {
                    -- Pending key sequence
                    {
                        function() return require("noice").api.status.pending.get() end,
                        cond = function() return package.loaded["noice"] and require("noice").api.status.pending.has() end,
                        color = function() return { fg = Snacks.util.color("Constant") } end,
                    },
                    -- stylua: ignore
                    {
                        function() return require("noice").api.status.command.get() end,
                        cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
                        color = function() return { fg = Snacks.util.color("Statement") } end,
                    },
                    -- stylua: ignore
                    {
                        function() return "  " .. require("dap").status() end,
                        cond = function() return package.loaded["dap"] and require("dap").status() ~= "" end,
                        color = function() return { fg = Snacks.util.color("Debug") } end,
                    },
                },
                lualine_y = {
                    {
                        "diagnostics",
                        sections = { "error", "warn", "info" },
                        symbols = {
                            error = icons.diagnostics.Error,
                            warn = icons.diagnostics.Warn,
                            info = icons.diagnostics.Info,
                            hint = icons.diagnostics.Hint,
                        },
                        -- always_visible = true,
                    },
                    -- Acts as a padding that always there so that even if filetype icon is not visible, the filename will still have some padding
                    {
                        function()
                            return " "
                        end,
                        padding = { left = 0, right = 0 },
                    },
                    {
                        "filetype",
                        icon_only = true,
                        colored = false,
                        padding = { left = 0, right = 1 },
                        separator = "|",
                    },
                    {
                        "filename",
                        fmt = function(filename)
                            return filename:gsub("neo%-tree filesystem %[%d+%]", "neo-tree.nvim")
                        end,
                        padding = { left = 1, right = 1 },
                        symbols = {
                            modified = " ",
                            readonly = "󰌾",
                        },
                        separator = "|",
                    },
                    {
                        function()
                            return Util.buffer.count_file_buffers()
                        end,
                    },
                },
                lualine_z = {
                    { "location", padding = { left = 1, right = 1 }, separator = "|" },
                    { "progress", padding = { left = 1, right = 1 } },
                },
            },
            extensions = { "neo-tree", "lazy", "fzf" },
        }

        local trouble = require("trouble")
        local symbols = trouble.statusline({
            mode = "symbols",
            groups = {},
            title = false,
            filter = { range = true },
            format = "{kind_icon}{symbol.name:Normal}",
            hl_group = "lualine_c_normal",
        })
        table.insert(opts.sections.lualine_c, {
            symbols and symbols.get,
            cond = function()
                return vim.b.trouble_lualine ~= false and symbols.has()
            end,
        })

        return opts
    end,
}
