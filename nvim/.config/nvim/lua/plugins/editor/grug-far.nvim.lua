return {
  require('utils.ui').catppuccin(function(palette)
    return {
      GrugFarResultsMatch = { link = 'Search' },
      GrugFarPreview = { link = 'Search' },
      GrugFarResultsAddIndicator = { fg = palette.green },
      GrugFarResultsChangeIndicator = { fg = palette.yellow },
      GrugFarResultsRemoveIndicator = { fg = palette.red },
    }
  end),
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
            ext = name:match('%.([^%.]+)$')
          end
          grug.open({
            transient = true,
            prefills = {
              filesFilter = ext and ext ~= '' and '*.' .. ext or nil,
            },
          })
        end,
        mode = { 'n', 'v' },
        desc = 'Search and Replace',
      },
    },

    opts = function()
      local ui_utils = require('utils.ui')
      local size_configs = require('configs.size')
      local preview_cols, preview_rows = ui_utils.computed_size(size_configs.side_preview.md)
      local panel_cols, _ = ui_utils.computed_size(size_configs.side_panel.md)
      local preview_height_offset = math.floor((vim.o.lines - preview_rows) / 2) - 1

      return {
        windowCreationCommand = panel_cols .. 'vsplit',
        wrap = false,

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
        previewWindow = {
          row = preview_height_offset,
          col = -preview_cols - 3,
          title = require('configs.picker').preview_title,
          title_pos = 'center',
          width = preview_cols,
          height = preview_rows,
        },
      }
    end,
  },
}
