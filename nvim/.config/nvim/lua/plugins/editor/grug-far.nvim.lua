return {
  require('utils.ui').catppuccin(function()
    return {
      GrugFarResultsMatch = { link = 'Search' },
      GrugFarPreview = { link = 'Search' },
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
          local ext = vim.bo.buftype == '' and vim.fn.expand('%:e')
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
      local preview_height_offset = math.floor((vim.opt.lines:get() - preview_rows) / 2) - 1

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
          title = ' ' .. require('plugins.editor.telescope.utils').preview_title .. ' ',
          title_pos = 'center',
          width = preview_cols,
          height = preview_rows,
        },
      }
    end,
  },
}
