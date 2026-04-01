return {
  Catppuccin(function()
    return {
      CursorTabAddition = { link = 'DiffAdd' },
      CursorTabDeletion = { link = 'DiffDelete' },
      CursorTabModification = { link = 'DiffText' },
      CursorTabCompletion = { link = 'Comment' },
    }
  end),
  {
    'cursortab/cursortab.nvim',
    build = 'cd server && go build',
    enabled = true,

    -- This plugin is more responsive when loaded early for some reason
    lazy = false,
    priority = Priority.FEATURE,

    event = 'BufReadPost',
    opts = function()
      return {
        -- provider = {
        --   type = 'sweepapi',
        --   api_key_env = 'SWEEPAPI_TOKEN',
        --   model = 'sweep-next-edit-7b',
        -- },
        provider = {
          type = 'copilot',
        },
      }
    end,
  },
}
