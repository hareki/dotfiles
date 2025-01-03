local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  -- bootstrap lazy.nvim
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
    lazypath })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

local lg_size = Constant.ui.popup_size.lg
require("lazy").setup({
  ui = {
    size = { width = lg_size.WIDTH, height = lg_size.HEIGHT },
    border = "rounded",
    backdrop = 100,
    title = " Lazy ",
  },
  rocks = {
    hererocks = true,
  },
  spec = {
    { "Hareki/LazyVim", import = "lazyvim.plugins" },

    { import = "plugins.core" },

    { import = "plugins.extras.coding" },
    { import = "plugins.extras.editor" },
    { import = "plugins.extras.lang" },
    { import = "plugins.extras.tmux" },
    { import = "plugins.extras.ui" },

    { import = "plugins.overrides.coding" },
    { import = "plugins.overrides.editor" },

    { import = "plugins.overrides.extras.ai" },
    { import = "plugins.overrides.extras.coding" },
    { import = "plugins.overrides.extras.editor" },
    { import = "plugins.overrides.extras.ui" },

    { import = "plugins.overrides.formatting" },
    { import = "plugins.overrides.linting" },
    { import = "plugins.overrides.lsp" },
    { import = "plugins.overrides.ui" },
  },

  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  change_detection = {
    notify = false,
  },
  -- automatically check for plugin updates
  -- temporarily disable it since it hurts startup time
  checker = { enabled = false, notify = false },
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
