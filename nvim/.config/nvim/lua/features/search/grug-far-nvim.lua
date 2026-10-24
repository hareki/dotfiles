-- grug-far passes previewWindow straight to nvim_open_win, so geometry must be plain numbers,
-- computed per open; the static opts below only cover direct :GrugFar invocations
local function preview_geometry()
  local preview = UI.layout.side_preview()
  local panel_cols = UI.layout.side_size('side_panel', 'md')

  return {
    window_creation_command = panel_cols .. 'vsplit',
    preview_window = {
      row = preview.row,
      col = preview.col,
      title = Conf.picker.PREVIEW_TITLE,
      title_pos = 'center',
      width = preview.width,
      height = preview.height,
    },
  }
end

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
          local ext = nil

          if vim.bo.buftype == '' then
            local name = vim.api.nvim_buf_get_name(0)
            -- From the file name, so a dotted dir (`b.c/Makefile`) can't pose as an extension;
            -- unlike fnamemodify(':e'), `.bashrc` gives `*.bashrc`, so rg searches the hidden file
            ext = vim.fs.basename(name):match('%.([^%.]+)$')
          end

          local geometry = preview_geometry()
          grug.open({
            transient = true,
            windowCreationCommand = geometry.window_creation_command,
            previewWindow = geometry.preview_window,
            prefills = {
              filesFilter = ext and '*.' .. ext or nil,
            },
          })
        end,
        mode = { 'n', 'v' },
        desc = 'Search and Replace',
      },
    },

    opts = function()
      local geometry = preview_geometry()

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
