--- Create a which-key.nvim plugin spec with group specs and/or icon rules
--- Returns a lazy.nvim spec that contributes to which-key's configuration.
--- Icon rules are prepended (higher priority than generic rules in the main spec).
--- @module 'which-key'
--- @param config { specs?: wk.Spec, rules?: wk.IconRule | wk.IconRule[] }
--- @return table spec A lazy.nvim plugin spec for which-key.nvim
local function which_key(config)
  local specs = config.specs
  local rules = config.rules

  -- Normalize: single spec { '<leader>a', group = '...' } → list of specs
  if specs and type(specs[1]) == 'string' then
    specs = { specs }
  end

  -- Normalize: single rule { pattern = '...' } → list of rules
  if rules and (rules.pattern or rules.plugin) then
    rules = { rules }
  end

  return {
    'hareki/which-key.nvim',
    opts = function(_, opts)
      if specs then
        opts.spec = opts.spec or {}
        vim.list_extend(opts.spec, specs)
      end

      if rules then
        opts.icons = opts.icons or {}
        opts.icons.rules = opts.icons.rules or {}
        -- Prepend: plugin-specific rules have higher priority than generic ones
        for i, rule in ipairs(rules) do
          table.insert(opts.icons.rules, i, rule)
        end
      end
    end,
  }
end

--- @class utils.ui.which_key
--- @overload fun(config: { specs?: wk.Spec, rules?: wk.IconRule | wk.IconRule[] }): table

--- @type utils.ui.which_key
local M = setmetatable({}, {
  __call = function(_, config)
    return which_key(config)
  end,
})

return M
