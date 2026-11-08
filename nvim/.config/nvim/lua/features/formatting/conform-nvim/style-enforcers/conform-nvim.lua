--- The format step for conform's formatters
--- @class features.formatting.conform-nvim.style-enforcers.conform-nvim: features.formatting.conform-nvim.style-enforcers.Step
local M = {
  name = 'conform',
  label = 'Formatting',
}

--- @param formatters conform.FormatterInfo[]
--- @param uses_lsp boolean
--- @return string names
local function formatter_names(formatters, uses_lsp)
  local names = vim.tbl_map(function(formatter)
    return formatter.name
  end, formatters)

  if uses_lsp then
    names[#names + 1] = 'lsp'
  end

  return table.concat(names, ', ')
end

--- Whether conform has formatters to run on the buffer
--- @param buf integer
--- @return boolean
function M.applies(buf)
  local conform = require('conform')
  local formatters, uses_lsp = conform.list_formatters_to_run(buf)
  return #formatters > 0 or uses_lsp
end

--- @param ctx features.formatting.conform-nvim.style-enforcers.Context
--- @return nil
function M.run(ctx)
  local conform = require('conform')
  conform.format({
    async = true,
    bufnr = ctx.buf,
    quiet = true,
  }, ctx.done)
end

--- @param err string
--- @param debug? boolean
--- @param buf integer
--- @return features.formatting.conform-nvim.style-enforcers.Failure
function M.failure(err, debug, buf)
  local msg
  if debug then
    msg = 'Format error: ' .. err
  else
    local conform = require('conform')
    local formatters, uses_lsp = conform.list_formatters_to_run(buf)
    msg = string.format(
      'Formatter(s) used: `%s` \nSee `:ConformInfo` for more information',
      formatter_names(formatters, uses_lsp)
    )
  end

  return { level = 'error', title = 'Formatting Failed', msg = msg }
end

return M
