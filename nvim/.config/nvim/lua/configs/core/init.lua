require('lua.configs.core.ensure-lazy')

-- [[ Configure and install plugins ]]
local lg_size = Constant.ui.popup_size.lg
require('lazy').setup({
    ui = {
        size = { width = lg_size.WIDTH, height = lg_size.HEIGHT },
        border = "rounded",
        backdrop = 100,
        title = " Lazy ",
    },
    spec = {
        { import = "plugins.coding" },
        { import = "plugins.editor" },
        { import = "plugins.formatting" },
        { import = "plugins.linting" },
        { import = "plugins.lsp" },
        { import = "plugins.ui" }
    },
    checker = { enabled = false, notify = false },
    defaults = {
        lazy = true,
        version = false, -- Always use the latest git commit
    },
    performance = {
        rtp = {
            disabled_plugins = {
                "gzip",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
            },
        },
    },
}
)
