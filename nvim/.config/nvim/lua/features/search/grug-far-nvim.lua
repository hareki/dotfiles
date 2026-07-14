-- grug-far feeds previewWindow straight into nvim_open_win (no callables or
-- fractions), so geometry must be plain numbers. Computing them here and
-- calling this per open keeps the panel and preview sized for the current
-- screen; the static opts below only cover direct :GrugFar invocations
local function preview_geometry()
  local preview_cols, preview_rows = UI.layout.side_size('side_preview', 'md')
  local panel_cols, _ = UI.layout.side_size('side_panel', 'md')

  return {
    window_creation_command = panel_cols .. 'vsplit',
    preview_window = {
      row = math.floor((vim.o.lines - preview_rows) / 2) - 1,
      col = -preview_cols - 3,
      title = Conf.picker.PREVIEW_TITLE,
      title_pos = 'center',
      width = preview_cols,
      height = preview_rows,
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
            ext = name:match('%.([^%.]+)$')
          end

          local geometry = preview_geometry()
          grug.open({
            transient = true,
            windowCreationCommand = geometry.window_creation_command,
            previewWindow = geometry.preview_window,
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
