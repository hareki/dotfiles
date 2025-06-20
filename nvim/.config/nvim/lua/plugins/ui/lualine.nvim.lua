return {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    init = function()
        if vim.fn.argc(-1) > 0 then
            -- Set an empty statusline till lualine loads
            vim.o.statusline = " "
        else
            -- Hide the statusline on the starter page
            vim.o.laststatus = 0
        end
    end,
    opts = function()
        -- PERF: we don't need this lualine require madness 🤷
        local lualine_require = require("lualine_require")
        lualine_require.require = require
        local palette = Util.get_palette()
        local icons = Constant.icons

        local mode_hl = {
            -- NORMAL & friends
            NORMAL        = { fg = palette.surface0, bg = palette.blue, gui = 'bold' },
            ['O-PENDING'] = { fg = palette.surface0, bg = palette.blue, gui = 'bold' },

            -- VISUAL family (Visual, Select, block, etc.)
            VISUAL        = { fg = palette.base, bg = palette.mauve, gui = 'bold' },
            ['V-LINE']    = { fg = palette.base, bg = palette.mauve, gui = 'bold' },
            ['V-BLOCK']   = { fg = palette.base, bg = palette.mauve, gui = 'bold' },

            SELECT        = { fg = palette.base, bg = palette.mauve, gui = 'bold' },
            ['S-LINE']    = { fg = palette.base, bg = palette.mauve, gui = 'bold' },
            ['S-BLOCK']   = { fg = palette.base, bg = palette.mauve, gui = 'bold' },

            -- INSERT (also used for Terminal/Shell because the theme re-uses the same colours)
            INSERT        = { fg = palette.base, bg = palette.green, gui = 'bold' },
            SHELL         = { fg = palette.base, bg = palette.green, gui = 'bold' },
            TERMINAL      = { fg = palette.base, bg = palette.green, gui = 'bold' },

            -- REPLACE family
            REPLACE       = { fg = palette.base, bg = palette.red, gui = 'bold' },
            ['V-REPLACE'] = { fg = palette.base, bg = palette.red, gui = 'bold' },

            -- COMMAND/EX/MORE/CONFIRM share the same colours
            COMMAND       = { fg = palette.base, bg = palette.peach, gui = 'bold' },
            EX            = { fg = palette.base, bg = palette.peach, gui = 'bold' },
            MORE          = { fg = palette.base, bg = palette.peach, gui = 'bold' },
            CONFIRM       = { fg = palette.base, bg = palette.peach, gui = 'bold' },
        }

        local reset_theme = {
            normal   = {
                a = { fg = palette.surface0, bg = palette.mantle },
                b = { fg = palette.surface0, bg = palette.mantle },
                c = { fg = palette.surface0, bg = palette.mantle },
            },
            insert   = {
                a = { fg = palette.surface0, bg = palette.mantle },
                b = { fg = palette.surface0, bg = palette.mantle },
                c = { fg = palette.surface0, bg = palette.mantle },
            },
            visual   = {
                a = { fg = palette.surface0, bg = palette.mantle },
                b = { fg = palette.surface0, bg = palette.mantle },
                c = { fg = palette.surface0, bg = palette.mantle },
            },
            replace  = {
                a = { fg = palette.surface0, bg = palette.mantle },
                b = { fg = palette.surface0, bg = palette.mantle },
                c = { fg = palette.surface0, bg = palette.mantle },
            },
            inactive = {
                a = { fg = palette.surface0, bg = palette.mantle },
                b = { fg = palette.surface0, bg = palette.mantle },
                c = { fg = palette.surface0, bg = palette.mantle },
            },
        }

        local function inverse_mode_hl(mode)
            local c = mode_hl[mode]
            return { fg = c.bg, bg = c.fg, gui = c.gui }
        end

        -- From lualine.nvim slanted gaps example
        local empty = require('lualine.component'):extend()
        function empty:draw(default_highlight)
            self.status = ' '
            self.applied_separator = ''
            self:apply_highlights(default_highlight)
            self:apply_section_separators()
            return self.status
        end

        local empty_comp = {
            empty,
            color = { fg = palette.mantle, bg = palette.mantle },
            padding = { left = 0, right = 0 },
            separator = { left = "", right = "" },
        }

        return {
            options = {
                theme = reset_theme,
                globalstatus = vim.o.laststatus == 3,
                disabled_filetypes = { statusline = { "dashboard", "netrw" } },
                padding = { left = 0, right = 0 },
                sections_separators = { left = '', right = '' },
                component_separators = { left = '', right = '' },
            },


            sections = {
                lualine_a = {
                    {
                        'mode',
                        fmt = string.lower,
                        icon = {
                            -- "󰀵 ",
                            " ",
                            color = function()
                                local mode = require('lualine.utils.mode').get_mode()
                                return mode_hl[mode]
                            end
                        },
                        separator = { left = "", right = "", },
                        color = function()
                            local mode = require('lualine.utils.mode').get_mode()
                            return inverse_mode_hl(mode)
                        end
                    },

                    empty_comp,

                    {
                        "filetype",
                        icon_only = true,
                        colored = false,
                        separator = { left = "" },
                        color = { bg = palette.mauve, fg = palette.mantle },

                    },
                    {
                        "filename",
                        fmt = function(filename)
                            return filename:gsub("neo%-tree filesystem %[%d+%]", "neo-tree.nvim")
                        end,
                        padding = { left = 1, },
                        symbols = {
                            modified = " ",
                            readonly = "󰌾",
                        },
                        separator = { right = "" },
                        color = { fg = palette.mauve, bg = palette.surface0 },
                    },
                    {
                        "branch",
                        icon = '',
                        fmt = Util.git.format_branch_name,
                        color = { fg = palette.subtext0, bg = palette.mantle },
                        padding = { left = 2, right = 0 },
                    },
                    {
                        "diff",
                        padding = { left = 2, right = 0 },
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
                lualine_b = {},
                lualine_c = {},
                lualine_x = {},
                lualine_y = {},
                lualine_z = {
                    {
                        'lsp_status',
                        icon = '', -- f013
                        symbols = {
                            spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' },
                            done = '✓',
                            separator = ' ',
                        },
                        ignore_lsp = {},
                    },
                    {
                        "diagnostics",
                        sections = { "error", "warn", "info" },
                        symbols = {
                            error = icons.diagnostics.Error,
                            warn = icons.diagnostics.Warn,
                            info = icons.diagnostics.Info,
                            hint = icons.diagnostics.Hint,
                        },
                        always_visible = true,
                        padding = { left = 0, right = 2 },
                    },

                    {
                        function()
                            return Util.git.get_repo_name()
                        end,
                        color = { fg = palette.pink, bg = palette.surface0 },
                        separator = { left = "", right = "", },
                        icon = {
                            -- "󱉭 ",
                            " ",
                            color = { fg = palette.mantle, bg = palette.pink }
                        },
                        padding = { left = 0, right = 0 },
                    },

                    empty_comp,

                    {
                        "progress",
                        padding = { left = 0, right = 0 },
                        color = { fg = palette.green, bg = palette.surface0 },
                        icon = {
                            ' ',
                            color = { fg = palette.surface0, bg = palette.green },
                        },
                        separator = { left = "", right = "", },
                    },
                },
            },
            extensions = { "neo-tree", "lazy", "fzf" },
        }
    end,
}
