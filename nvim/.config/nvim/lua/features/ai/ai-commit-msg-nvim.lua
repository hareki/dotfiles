return {
  'hareki/ai-commit-msg.nvim',
  ft = 'gitcommit',
  opts = function()
    local noice_spinners = require('noice.util.spinners')
    local circle_full_frames = noice_spinners.spinners.circleFull.frames

    return {
      provider = 'anthropic',
      spinner = circle_full_frames,
      cost_display = 'verbose',
      providers = {
        anthropic = {
          model = 'claude-haiku-4-5',
          -- Required by the Anthropic Messages API
          max_tokens = 10000,
        },
      },
    }
  end,
}
