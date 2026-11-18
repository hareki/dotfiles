return {
  opts = {
    init_options = {
      config = '~/.config/typos/typos.toml',
    },
  },

  setup = function()
    -- This server checks the spelling (datword suggests), so the built-in checker has no language
    vim.opt.spelllang = {}
  end,
}
