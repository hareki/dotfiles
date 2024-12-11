return {
  setup = function()
    vim.api.nvim_set_option_value("guicursor", "n-v:block,i-c-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkon1", {
      scope = "global",
    })
  end,
}
