--- A which-key.nvim spec fragment adding group specs, icon rules (ahead of the generic ones the
--- base spec's `config` appends) and/or manual triggers (for single-letter builtins like `l`)
--- @module 'which-key'
--- @param config { specs?: wk.Spec, rules?: wk.IconRule | wk.IconRule[], triggers?: wk.Spec }
--- @return table spec
local function which_key(config)
  local rules = config.rules

  -- Normalize: single rule { pattern = '...' } => list of rules
  if rules and (rules.pattern or rules.plugin) then
    rules = { rules }
  end

  return {
    'hareki/which-key.nvim',
    opts = {
      -- Wrapped, or a single spec's fields would spill into the merged list; which-key parses
      -- nested lists, so a single spec and a list of them both fit
      spec = { config.specs },
      icons = { rules = rules },
      triggers = { config.triggers },
    },
    -- On every fragment: lazy.nvim only honors it on fragments merged after the one setting it
    opts_extend = { 'spec', 'icons.rules', 'triggers' },
  }
end

return which_key
