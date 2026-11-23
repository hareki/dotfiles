-- A tool that opened nvim as its editor (NVIM_INTEGRATION) shows its label in place of lualine
return {
  UI.catppuccin(UI.integration.highlights),

  {
    'integration-statusline',
    virtual = true,
    enabled = UI.integration.host ~= nil,

    init = function()
      vim.opt.statusline = UI.integration.statusline()
    end,
  },
}
