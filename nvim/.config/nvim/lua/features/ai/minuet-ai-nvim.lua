return {
  UI.catppuccin(function(palette)
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
      request_timeout = Conf.Cmp.ai_cmp_timeout_ms / 1000,
      n_completions = Conf.Cmp.ai_cmp_max_items,
      throttle = 2500,
      debounce = 500,
      provider = 'openai_fim_compatible',
      provider_options = {
        openai_fim_compatible = {
          -- Need to be `Minuet` so that blink.cmp can look up the correct icon with kind = `Minuet`
          name = 'Minuet',
          model = 'mercury-edit-2',
          end_point = 'https://api.inceptionlabs.ai/v1/fim/completions',
          api_key = 'MERCURY_API_KEY',
          stream = true,
        },
      },
    },
  },
}
