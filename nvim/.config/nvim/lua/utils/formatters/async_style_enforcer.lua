local M = {}

local running_bufs = {}

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

  return #names > 0 and table.concat(names, ', ') or 'No formatter found'
end

---@param debug boolean|nil
function M.run(debug)
  local buf = vim.api.nvim_get_current_buf()

  -- Prevent concurrent format+lint operations on the same buffer
  if running_bufs[buf] then
    local notifier = require('utils.notifier')
    notifier.warn('Formatting already in progress', { title = 'Style Enforcer' })
    return
  end

  running_bufs[buf] = true

  local function cleanup()
    running_bufs[buf] = nil
  end

  local conform = require('conform')
  local linters = require('utils.linters')

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

  local run_linters = function(formatted)
    local total = #linters.names_for_filetype(vim.bo[buf].filetype) + (formatted and 1 or 0)
    local done_count = formatted and 1 or 0
    local percentage = 100 / total

    linters.run_by_ft({
      bufnr = buf,
      on_start = function(linter_name)
        local label = 'Linting (' .. linter_name .. ')'
        if done_count == 0 then
          progress:start(label)
        else
          progress:report(label, percentage * done_count)
        end
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
          cleanup()
        end
      end,
    })
  end

  local formatters, uses_lsp = require('conform').list_formatters_to_run(buf)
  local should_format = (formatters and #formatters > 0) or uses_lsp

  if not should_format then
    run_linters(false)
    return
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
      progress:finish()
      cleanup()
      return
    end

    run_linters(true)
  end)
end

return M
