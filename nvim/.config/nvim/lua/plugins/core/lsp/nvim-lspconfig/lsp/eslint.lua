local eslint_registered = false

return {
  opts = function()
    local base_on_eslint_attach = vim.lsp.config.eslint.on_attach

    return {
      on_attach = function(client, bufnr)
        if base_on_eslint_attach then
          base_on_eslint_attach(client, bufnr)
        end

        if eslint_registered then
          return
        end

        local linters = require('utils.linters')
        local eslint = require('utils.linters.eslint')

        linters.register(
          'eslint',
          { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' },
          eslint.run
        )

        eslint_registered = true
      end,
    }
  end,

  setup = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('eslint_lsp_attach', { clear = true }),
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client or client.name ~= 'eslint' then
          return
        end

        client:notify('$/setTrace', { value = 'verbose' }) -- Ask server to emit trace

        -- Use circular buffer to avoid O(n) table.remove operation
        local store, max = {}, 200
        local store_index = 0 -- Current write position
        local store_count = 0 -- Number of entries written
        local function push(line)
          store_index = (store_index % max) + 1
          store[store_index] = line
          store_count = store_count + 1
        end

        local original_trace = client.handlers['$/logTrace']
        local original_log = client.handlers['window/logMessage']
          or vim.lsp.handlers['window/logMessage']

        client.handlers['$/logTrace'] = function(err, params, ctx, cfg)
          push(
            ('%s %s%s'):format(os.date('%Y-%m-%d %H:%M:%S '), params.message, params.verbose or '')
          )
          if original_trace then
            return original_trace(err, params, ctx, cfg)
          end
        end

        client.handlers['window/logMessage'] = function(err, params, ctx, cfg)
          local lvl = ({ 'Error', 'Warn', 'Info', 'Log' })[params.type] or tostring(params.type)
          push(('%s [%s] %s'):format(os.date('%Y-%m-%d %H:%M:%S'), lvl, params.message))
          if original_log then
            original_log(err, params, ctx, cfg)
          end
        end

        vim.api.nvim_create_user_command('EslintLog', function()
          -- Reconstruct log in correct order from circular buffer
          local lines = {}
          local actual_count = math.min(store_count, max)

          if store_count <= max then
            -- Haven't wrapped around yet, store is in order
            for i = 1, actual_count do
              lines[i] = store[i]
            end
          else
            -- Wrapped around, need to reconstruct order
            local start_idx = (store_index % max) + 1
            for i = 1, max do
              local idx = ((start_idx + i - 2) % max) + 1
              lines[i] = store[idx]
            end
          end

          local buf = vim.api.nvim_create_buf(false, true)
          vim.bo[buf].filetype = 'eslint-log'
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
          vim.cmd.split({ mods = { split = 'botright' }, range = { 15 } })
          vim.api.nvim_win_set_buf(0, buf)
        end, {
          force = true, -- Override any previous definition
        })
      end,
    })
  end,
}
