return {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    config = function(plugin)
        Util.on_load("telescope.nvim", function()
            local ok, err = pcall(require("telescope").load_extension, "fzf")
            if not ok then
                local lib = plugin.dir .. "/build/libfzf.so"
                if not vim.uv.fs_stat(lib) then
                    Util.notification.warn("`telescope-fzf-native.nvim` not built. Rebuilding...")
                    require("lazy").build({ plugins = { plugin }, show = false }):wait(function()
                        Util.notification.info("Rebuilding `telescope-fzf-native.nvim` done.\nPlease restart Neovim.")
                    end)
                else
                    Util.notification.error("Failed to load `telescope-fzf-native.nvim`:\n" .. err)
                end
            end
        end)
    end,
}
