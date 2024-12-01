return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    opts.setup.tailwindcss = function(_, tailwind_opts)
      local experimental = Util.ensure_nested(tailwind_opts, "settings.tailwindCSS.experimental")
      experimental.classRegex = {
        "`tw([^`]*)", -- `tw ...`
        "'tw([^']*)", -- 'tw ...'
        '"tw([^"]*)', -- "tw ..."
      }
    end
  end,
}
