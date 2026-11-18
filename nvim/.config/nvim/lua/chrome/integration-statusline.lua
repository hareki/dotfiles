-- A tool that opened nvim as its editor (NVIM_INTEGRATION) shows its label in place of lualine
return {
  UI.catppuccin(UI.integration.highlights),

  {
    'integration-statusline',
    virtual = true,
    enabled = UI.integration.host ~= nil,

    init = function()
      local opt = vim.opt

      opt.statusline = UI.integration.statusline()
      opt.showmode = false -- As under lualine, whose init is not there to turn it off
    end,
  },
}
