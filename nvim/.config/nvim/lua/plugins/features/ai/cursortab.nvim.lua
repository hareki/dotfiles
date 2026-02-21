return {
  Catppuccin(function()
    return {
      CursorTabAddition = { link = 'DiffAdd' },
      CursorTabDeletion = { link = 'DiffDelete' },
      CursorTabModification = { link = 'DiffChange' },
      CursorTabCompletion = { link = 'Comment' },
    }
  end),
  {
    'hareki/cursortab.nvim',
    build = 'cd server && go build',
    event = 'BufReadPost',
    opts = function()
      return {
        provider = {
          type = 'sweepapi',
          api_key_env = 'SWEEPAPI_TOKEN',
          model = 'sweep-next-edit-7b',
        },
      }
    end,
  },
}
