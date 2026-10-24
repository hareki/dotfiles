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
          model = 'claude-haiku-5-5',
          max_tokens = 10000, -- Required by the Anthropic Messages API

          -- The plugin's pricing table lacks this model (cost_display then shows nothing) and
          -- takes flat rates only, so these are the rates for prompts up to 100K tokens
          pricing = {
            ['claude-haiku-5-5'] = { input_per_million = 0.10, output_per_million = 0.50 },
          },
        },
      },
    }
  end,
}
