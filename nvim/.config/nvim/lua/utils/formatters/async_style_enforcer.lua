local M = {}
function M.run()
  local conform = require('conform')
  local linters = require('utils.linters')
  local buf = vim.api.nvim_get_current_buf()

  local progress = require('utils.progress').create({
    pending_ms = 0,
    client_name = 'stenfo',
  })

  progress:start('Formatting')

  conform.format({
    async = true,
    bufnr = buf,
  }, function(err)
    if err then
      vim.notify('Prettier error: ' .. err, vim.log.levels.ERROR)
      return
    end

    local total = #linters.names_for_filetype(vim.bo[buf].filetype) + 1 -- Formater is already done
    local done_count = 1
    local percentage = 100 / total

    linters.run_by_ft({
      bufnr = buf,
      on_start = function(name)
        progress:report('Linting (' .. name .. ')', percentage * done_count)
      end,
      on_done = function(name, ok, err)
        if not ok and err then
          vim.notify(('%s failed: %s'):format(name, err), vim.log.levels.WARN)
        end

        done_count = done_count + (name == 'none' and 0 or 1)
        if done_count == total then
          if vim.bo[buf].modified then
            vim.api.nvim_buf_call(buf, function()
              vim.cmd.write()
            end)
          end

          progress:finish()
        end
      end,
    })
  end)
end

return M
