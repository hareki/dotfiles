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
          max_tokens = 10000, -- Required by the Anthropic Messages API

          -- The plugin's default pricing table doesn't cover this model, and
          -- cost_display silently shows nothing without a matching entry
          -- https://platform.claude.com/docs/en/about-claude/pricing
          pricing = {
            ['claude-haiku-4-5'] = { input_per_million = 1.00, output_per_million = 5.00 },
          },
        },
      },
    }
  end,
}
