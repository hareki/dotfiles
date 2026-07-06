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
    'cursortab/cursortab.nvim',
    -- Quite token expensive , I'm still considering it...
    enabled = false,
    build = 'cd server && go build',

    event = 'InsertEnter',
    opts = function()
      return {
        provider = {
          type = 'mercuryapi',
          api_key_env = Conf.Cmp.ai_mercury_key,
        },
      }
    end,
  },
}
