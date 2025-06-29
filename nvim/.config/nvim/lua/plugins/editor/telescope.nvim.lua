return {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    version = false, -- telescope did only one release, so use HEAD for now
    dependencies = {
        "nvim-telescope/telescope-fzf-native.nvim"
    },
    keys = {
        {
            "<leader>ff",
            function()
                require("telescope.builtin").find_files()
            end,
            desc = "Find Files",
        },
        {
            "<leader>fg",
            function()
                require("telescope.builtin").live_grep()
            end,
            desc = "Live Grep",
        },
        {
            "<leader>fb",
            function()
                require("telescope.builtin").buffers()
            end,
            desc = "Find Buffers",
        },
    },
    opts = function()
        local actions = require("telescope.actions")
        local layout_strategies = require("telescope.pickers.layout_strategies")
        local builtin = require("telescope.builtin")
        local lg_size = Constant.ui.popup_size.lg

        local function find_command()
            if 1 == vim.fn.executable("rg") then
                return { "rg", "--files", "--color", "never", "-g", "!.git" }
            elseif 1 == vim.fn.executable("fd") then
                return { "fd", "--type", "f", "--color", "never", "-E", ".git" }
            elseif 1 == vim.fn.executable("fdfind") then
                return { "fdfind", "--type", "f", "--color", "never", "-E", ".git" }
            elseif 1 == vim.fn.executable("find") and vim.fn.has("win32") == 0 then
                return { "find", ".", "-type", "f" }
            elseif 1 == vim.fn.executable("where") then
                return { "where", "/r", ".", "*" }
            end
        end

        -- Unify the preview title for all pickers
        local default_picker_configs = {}
        for picker_name, _ in pairs(builtin) do
            default_picker_configs[picker_name] = {
                preview_title = Constant.telescope.PREVIEW_TITLE,
            }
        end

        -- Define a custom layout based on "vertical", the point is to merge prompt and results windows
        -- In general, this layout mimics the "dropdown" theme, but take the "previewer" panel into account of the height layout
        -- https://www.reddit.com/r/neovim/comments/10asvod/telescopenvim_how_to_remove_windows_titles_and/
        layout_strategies.vertical_merged = function(picker, max_columns, max_lines, layout_config)
            local layout = layout_strategies.vertical(picker, max_columns, max_lines, layout_config)
            -- 1. Collapse the blank row between *prompt* and *results*
            layout.results.line = layout.results.line - 1
            layout.results.height = layout.results.height + 1

            -- 2. Seems like telescope.nvim exclude the statusline when centering the layout,
            -- Which is different from our logic in `Util.ui.get_lg_popup_size()`
            -- So we need to adjust/shift the position if needed
            local target_row = Util.ui.get_lg_popup_size(true).row
            -- The top most component is the prompt window, so we use it as the anchor to adjust the position
            local top_line = layout.prompt.line

            -- Minus 1 for the top border and the other one
            -- Minus 1 for the difference of how nvim_open_win and telescope handle the position
            -- nvim_open_win puts the window BELOW the specified row, while telescope doesn't
            top_line = top_line - 2

            local shift = target_row - top_line
            if shift ~= 0 then
                for _, win in ipairs { layout.prompt, layout.results, layout.preview } do
                    if win then win.line = win.line + shift end
                end
            end

            return layout
        end

        return {
            defaults = {
                prompt_prefix = "   ",
                selection_caret = " ",
                results_title = false,
                -- Merge prompt and results windows
                -- https://github.com/nvim-telescope/telescope.nvim/blob/5972437de807c3bc101565175da66a1aa4f8707a/lua/telescope/themes.lua#L50
                borderchars = {
                    prompt = { "─", "│", " ", "│", "╭", "╮", "│", "│" },
                    results = { "─", "│", "─", "│", "├", "┤", "╯", "╰" },
                    preview = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
                },
                -- Make results appear from top to bottom
                -- https://github.com/nvim-telescope/telescope.nvim/issues/1933
                sorting_strategy = "ascending",

                layout_strategy = "vertical_merged",
                layout_config = {
                    vertical = {
                        mirror = true,

                        height = function()
                            return Util.ui.get_lg_popup_size(true).height
                        end,
                        width = function()
                            return Util.ui.get_lg_popup_size(true).width
                        end,

                        preview_height = 0.45,
                        preview_cutoff = 1, -- Preview should always show (unless previewer = false)
                        prompt_position = "top",
                    },
                },

                -- Open files in the first window that is an actual file.
                -- Use the current window if no other window is available.
                get_selection_window = function()
                    local wins = vim.api.nvim_list_wins()
                    table.insert(wins, 1, vim.api.nvim_get_current_win())
                    for _, win in ipairs(wins) do
                        local buf = vim.api.nvim_win_get_buf(win)
                        if vim.bo[buf].buftype == "" then
                            return win
                        end
                    end
                    return 0
                end,
                mappings = {
                    n = {
                        ["q"] = actions.close,
                    },
                },
            },
            pickers = vim.tbl_deep_extend("force", default_picker_configs, {
                find_files = {
                    find_command = find_command,
                    hidden = true,
                },
                buffers = {
                    select_current = true,
                    --https://github.com/nvim-telescope/telescope.nvim/issues/1145#issuecomment-903161099
                    mappings = {
                        n = {
                            ["x"] = require("telescope.actions").delete_buffer,
                        },
                    },
                },
            }),
        }
    end,
}
