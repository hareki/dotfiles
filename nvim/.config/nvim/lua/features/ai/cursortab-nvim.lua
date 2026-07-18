return {
  UI.catppuccin(function(palette, _, extension)
    local blended_yellow_bg = UI.color.blend_hex(palette.base, palette.yellow)

    return {
      CursorTabAddition = { bg = extension.diff_add_word },
      CursorTabDeletion = { bg = extension.diff_delete_word },
      CursorTabModification = { link = 'DiffText' },
      CursorTabCompletion = { link = 'Comment' },
      CursorTabJumpText = { fg = palette.yellow, bg = blended_yellow_bg },
      CursorTabJumpSymbol = { fg = blended_yellow_bg },
    }
  end, 'cursortab.nvim'),

  {
    'hareki/cursortab.nvim',
    build = 'cd server && go build',
    event = 'VeryLazy',
    opts = function()
      return {
        provider = {
          type = 'mercuryapi',
          api_key_env = Conf.cmp.AI_MERCURY_KEY,
        },
        ui = {
          jump = {
            shape = 'pill',
          },
        },
        behavior = {
          idle_completion_delay = 50,
          text_change_debounce = 50,
          ignore_filetypes = { '', 'terminal', 'grug-far' },
        },
      }
    end,
  },
}
