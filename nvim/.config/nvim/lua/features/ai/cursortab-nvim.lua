return {
  UI.catppuccin(function()
    return {
      CursorTabAddition = { link = 'DiffAdd' },
      CursorTabDeletion = { link = 'DiffDelete' },
      CursorTabModification = { link = 'DiffText' },
      CursorTabCompletion = { link = 'Comment' },
    }
  end),

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
      }
    end,
  },
}
