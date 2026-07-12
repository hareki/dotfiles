return {
  UI.catppuccin(function(palette)
    return {
      -- Hardcoded by the plugin
      BlinkCmpItemKindMinuet = { fg = palette.yellow },
    }
  end, 'minuet-ai.nvim'),

  {
    'milanglacier/minuet-ai.nvim',
    opts = function()
      return {
        context_window = 20000,
        request_timeout = Conf.cmp.AI_CMP_TIMEOUT_MS / 1000,
        n_completions = Conf.cmp.AI_CMP_MAX_ITEMS,
        throttle = 2500,
        debounce = 500,
        provider = 'openai_fim_compatible',
        provider_options = {
          openai_fim_compatible = {
            -- Need to be `Minuet` so that blink.cmp can look up the correct icon with kind = `Minuet`
            name = 'Minuet',
            model = 'mercury-edit-2',
            end_point = 'https://api.inceptionlabs.ai/v1/fim/completions',
            api_key = Conf.cmp.AI_MERCURY_KEY,
            stream = true,
          },
        },
      }
    end,
  },
}
