local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  -- bootstrap lazy.nvim
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
    lazypath })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

require("lazy").setup({
  rocks = {
    enabled = false,
  },
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    { import = "plugins.extras.coding" },
    { import = "plugins.extras.editor" },
    { import = "plugins.extras.lsp" },
    { import = "plugins.extras.tmux" },
    { import = "plugins.extras.ui" },

    { import = "plugins.overrides.coding" },
    { import = "plugins.overrides.colorscheme" },
    { import = "plugins.overrides.editor" },

    { import = "plugins.overrides.extras.coding" },
    { import = "plugins.overrides.extras.ui" },

    { import = "plugins.overrides.lsp" },
    { import = "plugins.overrides.ui" },
    { import = "plugins.overrides.disabled" },
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
  -- install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = true, notify = true }, -- automatically check for plugin updates
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
