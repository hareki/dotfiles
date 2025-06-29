return {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "hareki/nvim-tree-preview.lua",
    },
    keys = {
        { "<leader>e", ":NvimTreeToggle<cr>", desc = "Explorer NvimTree", remap = true, silent = true },
    },
    opts = function()
        local palette = Util.get_palette()
        local float_enabled = true
        local height_ratio = Constant.ui.popup_size.lg.HEIGHT -- 0.8
        local width_ratio = Constant.ui.popup_size.lg.WIDTH   -- 0.8

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
            update_focused_file = {
                enable = true,
                update_root = {
                    enable = true,
                    ignore_list = {},
                },
                exclude = false,
            },
            filters = {
                enable = true,
                git_ignored = false,
            },
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
                local preview_manager = require('nvim-tree-preview.manager')
                local api = require("nvim-tree.api")

                local function opts(desc, external_bufnr)
                    return { desc = 'nvim-tree: ' .. desc, buffer = external_bufnr or bufnr, noremap = true, silent = true, nowait = true }
                end

                local function close()
                    preview.close()
                    api.tree.close()
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
                            close()
                            return
                        end

                        if folder_action == "toggle"
                            or folder_action == 'expand' and not node.open
                            or folder_action == 'collapse' and node.open
                        then
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

                vim.schedule(
                    function()
                        preview.watch()
                        vim.keymap.set("n", "q", close, opts("Close", preview_manager.instance.preview_buf))
                    end
                )
                vim.keymap.set("n", "q", close, opts("Close"))
                vim.keymap.set("n", "c", api.fs.copy.node, opts("Copy"))
                vim.keymap.set("n", "x", api.fs.cut, opts("Cut"))
                vim.keymap.set("n", "p", api.fs.paste, opts("Paste"))
                vim.keymap.set("n", "/", api.live_filter.start, opts("Live Filter: Start"))

                vim.keymap.set("n", "d", api.fs.remove, opts("Delete"))
                vim.keymap.set("n", "y", api.fs.copy.filename, opts("Copy Name"))
                vim.keymap.set("n", "Y", api.fs.copy.relative_path, opts("Copy Relative Path"))

                vim.keymap.set("n", "<Right>", node_action('expand'), opts("Expand node"))
                vim.keymap.set("n", "<S-Right>", api.tree.expand_all, opts("Expand all nodes"))
                vim.keymap.set("n", "<Left>", node_action('collapse'), opts("Collapse node"))
                vim.keymap.set("n", "<S-Left>", api.tree.collapse_all, opts("Collapse all nodes"))
                vim.keymap.set("n", "<CR>", node_action('toggle'), opts("Open"))
            end,

            view = {
                number = true,
                relativenumber = true,
                width = float_enabled and function()
                    return math.floor(vim.opt.columns:get() * width_ratio)
                end or nil,

                float = {
                    enable = float_enabled,
                    quit_on_focus_loss = false,
                    open_win_config = function()
                        local screen_w = vim.opt.columns:get()
                        local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
                        local window_w = screen_w * width_ratio
                        local window_h = screen_h * height_ratio
                        local window_w_int = math.floor(window_w)
                        local window_h_int = math.floor(window_h / 2)

                        -- Minus 1 to account for the border
                        local col = math.floor((screen_w - window_w_int) / 2) - 1
                        local row = math.floor((screen_h - window_h_int * 2) / 2) - 1
                        return {
                            title = ' NvimTree ',
                            title_pos = 'center',
                            border = 'rounded',
                            relative = 'editor',
                            row = row,
                            col = col,
                            width = window_w_int,
                            height = window_h_int - 1,
                        }
                    end,
                },
            },
        }
    end
}
