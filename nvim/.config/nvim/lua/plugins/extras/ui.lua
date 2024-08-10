function Get_initial_path()
  -- Get the first argument passed to Neovim (which is usually the path)
  local first_arg = vim.fn.argv(0)

  -- If the path is relative, resolve it to an absolute path
  local initial_path = vim.fn.fnamemodify(first_arg, ":p")

  return initial_path
end
return {
  {
    "https://gitlab.com/HiPhish/rainbow-delimiters.nvim",
  },
  {
    "Bekaboo/dropbar.nvim",
    -- optional, but required for fuzzy finder support
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
    },
    opts = {
      sources = {
        path = {
          relative_to = function(_, win)
            -- return "/home/hareki/.config/nvim"
            return Get_initial_path()
            -- Workaround for Vim:E5002: Cannot find window number
            -- local ok, cwd = pcall(vim.fn.getcwd, win)
            -- return ok and cwd or vim.fn.getcwd()

            -- return "/home/hareki/Repositories/personal/dotfiles/"
            -- return LazyVim.lualine.pretty_path({
            --   relative = "cwd",
            --   length = 0,
            --   filename_hl = "none",
            -- })
          end,
        },
      },
    },
  },
}
