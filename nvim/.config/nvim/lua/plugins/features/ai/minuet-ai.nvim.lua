local limit = require('plugins.features.completion.blink-cmp.config.limit')

return {
  Catppuccin(function(palette)
    return {
      -- Hardcoded by the plugin
      BlinkCmpItemKindMinuet = { fg = palette.yellow },
    }
  end),

  {
    'milanglacier/minuet-ai.nvim',
    enabled = vim.g.ai_provider == 'mercury',
    opts = {
      context_window = 20000,
      request_timeout = limit.ai_cmp_timeout_ms / 1000,
      throttle = 1800,
      debounce = 400,
      provider = 'openai_fim_compatible',
      provider_options = {
        openai_fim_compatible = {
          -- Need to be `Minuet` so that blink.cmp can look up the correct icon with kind = `Minuet`
          name = 'Minuet',
          model = 'mercury-coder',
          end_point = 'https://api.inceptionlabs.ai/v1/fim/completions',
          api_key = 'MERCURY_API_KEY',
          stream = true,
        },
      },
    },
  },
}
