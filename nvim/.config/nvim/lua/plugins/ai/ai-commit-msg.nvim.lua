return {
  'hareki/ai-commit-msg.nvim',
  ft = 'gitcommit',
  opts = function()
    local noice_spinners = require('noice.util.spinners')
    local circle_full_frames = noice_spinners.spinners.circleFull.frames

    return {
      provider = 'copilot',
      spinner = circle_full_frames,
      cost_display = 'verbose',
      providers = {
        copilot = {
          model = 'gpt-5',
          max_tokens = 10000,
          reasoning_effort = 'low',
        },
      },
    }
  end,
}
