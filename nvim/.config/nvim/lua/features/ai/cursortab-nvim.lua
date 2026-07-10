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
    enabled = false, -- Quite token expensive , I'm still considering it...
    build = 'cd server && go build',

    event = 'InsertEnter',
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
