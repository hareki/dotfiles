local HEIGHT_RATIO = Constant.ui.popup_size.lg.HEIGHT
local WIDTH_RATIO = 0.5



return {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
        { "nvim-tree/nvim-web-devicons", },
        {
            'b0o/nvim-tree-preview.lua',
            dependencies = {
                'nvim-lua/plenary.nvim',
                '3rd/image.nvim', -- Optional, for previewing images
            },
        },
    },
    keys = {
        { "<leader>e", ":NvimTreeToggle<cr>", desc = "Explorer NvimTree", remap = true, silent = true },
    },
    opts = function()
        local palette = Util.get_palette()

        Util.highlights({
            NvimTreeSignColumn = {
                link = "NormalFloat"
            },
            NvimTreeCutHL = {
                bg = palette.maroon,
                fg = palette.base,
            },
            NvimTreeCopiedHL = {
                bg = palette.surface2,
                fg = palette.text,
            },

        })

        return {
            renderer = {
                icons = {
                    git_placement = "right_align",
                    glyphs = {
                        folder = {
                            arrow_closed = "",
                            arrow_open = "",
                            default = "",
                            open = "",
                            empty = "",
                            empty_open = "",
                            symlink = "",
                            symlink_open = "",
                        },
                        git = {
                            unstaged = "󰄱",
                            staged = "",
                            unmerged = "",
                            renamed = "󰁕",
                            untracked = "",
                            deleted = "",
                            ignored = "",
                        },
                    },
                }
            },
            on_attach = function(bufnr)
                local preview = require('nvim-tree-preview')
                local api = require("nvim-tree.api")

                local function opts(desc)
                    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
                end

                ---@param folder_action 'expand' | 'collapse' | 'toggle'
                local function node_action(folder_action)
                    return function()
                        local ok, node = pcall(api.tree.get_node_under_cursor)
                        if not ok or not node then
                            return
                        end

                        local is_file_node = node.nodes == nil

                        if is_file_node then
                            api.node.open.edit()
                            api.tree.close()
                            return
                        end

                        if folder_action == "toggle" then
                            api.node.open.edit()
                            return
                        end

                        if folder_action == "expand" and not node.open then
                            api.node.open.edit()
                        elseif folder_action == "collapse" and node.open then
                            api.node.open.edit()
                        end
                    end
                end


                vim.keymap.set('n', '<Tab>', function()
                    local ok, node = pcall(api.tree.get_node_under_cursor)
                    if not ok or not node then
                        return
                    end
                    local is_file_node = node.nodes == nil

                    if preview.is_open() and is_file_node then
                        preview.node(node, { toggle_focus = true })
                    end
                end, opts 'Preview')

                vim.keymap.set('n', 'P', preview.watch, opts 'Preview (Watch)')
                vim.keymap.set("n", "<Right>", node_action('expand'), opts("Expand node"))
                vim.keymap.set("n", "<S-Right>", api.tree.expand_all, opts("Expand all nodes"))
                vim.keymap.set("n", "<Left>", node_action('collapse'), opts("Collapse node"))
                vim.keymap.set("n", "<S-Left>", api.tree.collapse_all, opts("Collapse all nodes"))
                vim.keymap.set("n", "<CR>", node_action('toggle'), opts("Open"))

                vim.keymap.set("n", "d", api.fs.remove, opts("Delete"))
                vim.keymap.set("n", "y", api.fs.copy.filename, opts("Copy Name"))
                vim.keymap.set("n", "Y", api.fs.copy.relative_path, opts("Copy Relative Path"))

                vim.keymap.set("n", "c", api.fs.copy.node, opts("Copy"))
                vim.keymap.set("n", "x", api.fs.cut, opts("Cut"))
                vim.keymap.set("n", "p", api.fs.paste, opts("Paste"))

                vim.keymap.set("n", "q", api.tree.close, opts("Close"))
                vim.keymap.set("n", "/", api.live_filter.start, opts("Live Filter: Start"))
            end,
            view = {
                relativenumber = true,
                float = {
                    enable = true,
                    quit_on_focus_loss = false,
                    open_win_config = function()
                        local screen_w = vim.opt.columns:get()
                        local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
                        local window_w = screen_w * WIDTH_RATIO
                        local window_h = screen_h * HEIGHT_RATIO
                        local window_w_int = math.floor(window_w)
                        local window_h_int = math.floor(window_h)
                        local center_x = (screen_w - window_w) / 2
                        local center_y = ((vim.opt.lines:get() - window_h) / 2)
                            - vim.opt.cmdheight:get()
                        return {
                            title = ' NvimTree ',
                            title_pos = 'center',
                            border = 'rounded',
                            relative = 'editor',
                            row = center_y,
                            col = center_x,
                            width = window_w_int,
                            height = window_h_int,
                        }
                    end,
                },
                width = function()
                    return math.floor(vim.opt.columns:get() * WIDTH_RATIO)
                end,
            },
        }
    end
}
