local M = {}

local function get_formatter_names(buf)
  local list, uses_lsp = require('conform').list_formatters_to_run(buf)

  local names = {}
  for _, f in ipairs(list or {}) do
    if f and f.name then
      names[#names + 1] = f.name
    end
  end
  if uses_lsp then
    names[#names + 1] = 'lsp'
  end

  return #names > 0 and table.concat(names, ', ') or 'unknown'
end

---@param debug boolean|nil
function M.run(debug)
  local conform = require('conform')
  local linters = require('utils.linters')
  local buf = vim.api.nvim_get_current_buf()

  local progress = require('utils.progress').create({
    pending_ms = 0,
    client_name = 'stenfo',
  })

  local save = function()
    if vim.bo[buf].modified then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd.write()
      end)
    end
  end

  progress:start('Formatting')

  conform.format({
    async = true,
    bufnr = buf,
    quiet = true,
  }, function(format_error)
    if format_error then
      local msg = debug and 'Format error: ' .. format_error
        or ('Formatter(s) used: `%s` \nSee `:ConformInfo` for more information'):format(
          get_formatter_names(buf)
        )

      notifier.error(msg, {
        title = 'Formatting Failed',
      })
      save()
      return
    end

    local total = #linters.names_for_filetype(vim.bo[buf].filetype) + 1 -- Formater is already done
    local done_count = 1
    local percentage = 100 / total

    linters.run_by_ft({
      bufnr = buf,
      on_start = function(linter_name)
        progress:report('Linting (' .. linter_name .. ')', percentage * done_count)
      end,
      on_done = function(linter_name, ok, lint_error)
        if not ok and lint_error then
          local msg = debug and ('Linter %s error: %s'):format(linter_name, lint_error)
            or ('Linter used: %s'):format(linter_name)

          notifier.warn(msg, {
            title = 'Linting Failed',
          })
        end

        done_count = done_count + (linter_name == 'none' and 0 or 1)
        if done_count == total then
          save()
          progress:finish()
        end
      end,
    })
  end)
end

return M
