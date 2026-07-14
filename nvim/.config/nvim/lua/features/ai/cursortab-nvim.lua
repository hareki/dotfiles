return {
  UI.catppuccin(function(palette, _, extension)
    local blended_blue_bg = UI.color.blend_hex(palette.base, palette.blue)

    return {
      CursorTabAddition = { bg = extension.diff_add_word },
      CursorTabDeletion = { bg = extension.diff_delete_word },
      CursorTabModification = { link = 'DiffText' },
      CursorTabCompletion = { link = 'Comment' },
      CursorTabJumpText = { fg = palette.blue, bg = blended_blue_bg },
      CursorTabJumpSymbol = { fg = blended_blue_bg },
    }
  end, 'cursortab.nvim'),

  {
    'hareki/cursortab.nvim',
    branch = 'feat/inline-word-diff',
    build = 'cd server && go build',
    event = 'VeryLazy',
    opts = function()
      return {
        provider = {
          type = 'mercuryapi',
          api_key_env = Conf.cmp.AI_MERCURY_KEY,
        },
        behavior = {
          idle_completion_delay = 150,
          text_change_debounce = 150,
          ignore_filetypes = { '', 'terminal', 'grug-far' },
        },
      }
    end,
  },
}
