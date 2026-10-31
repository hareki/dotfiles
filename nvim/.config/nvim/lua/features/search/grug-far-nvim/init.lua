return {
  UI.catppuccin(function(palette)
    return {
      GrugFarResultsMatch = { link = 'Search' },
      GrugFarPreview = { link = 'Search' },

      GrugFarResultsAddIndicator = { fg = palette.green },
      GrugFarResultsChangeIndicator = { fg = palette.yellow },
      GrugFarResultsRemoveIndicator = { fg = palette.red },
    }
  end, 'grug-far.nvim'),

  {
    'hareki/grug-far.nvim',
    cmd = 'GrugFar',
    keys = {
      {
        '<leader>sr',
        function()
          local grug = require('grug-far')
          local utils = require('features.search.grug-far-nvim.utils')
          local ext

          if vim.bo.buftype == '' then
            local name = vim.api.nvim_buf_get_name(0)
            -- From the file name, so a dotted dir (`b.c/Makefile`) can't pose as an extension;
            -- unlike fnamemodify(':e'), `.bashrc` gives `*.bashrc`, so rg searches the hidden file
            ext = vim.fs.basename(name):match('%.([^%.]+)$')
          end

          local geometry = utils.preview_geometry()
          grug.open({
            transient = true,
            windowCreationCommand = geometry.window_creation_command,
            previewWindow = geometry.preview_window,
            prefills = {
              filesFilter = ext and '*.' .. ext,
            },
          })
        end,
        mode = { 'n', 'v' },
        desc = 'Search and Replace',
      },
    },

    opts = function()
      local utils = require('features.search.grug-far-nvim.utils')
      local geometry = utils.preview_geometry()

      return {
        windowCreationCommand = geometry.window_creation_command,
        wrap = false,
        prefills = {
          flags = '--fixed-strings --smart-case',
        },

        keymaps = {
          openNextLocation = false,
          openPrevLocation = false,
          prevInput = false,
          nextInput = false,

          togglePreview = {
            n = 'B',
          },
          smartToggleFocus = {
            n = '<Tab>',
          },
        },
        previewWindow = geometry.preview_window,
      }
    end,
  },
}
