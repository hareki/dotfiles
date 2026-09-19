-- Use circular buffer to avoid O(n) table.remove operation
local store, max = {}, 200
local store_index = 0 -- Current write position
local store_count = 0 -- Number of entries written

--- @param line string
local function push(line)
  store_index = (store_index % max) + 1
  store[store_index] = line:gsub('\n', ' ')
  store_count = store_count + 1
end

return {
  opts = {
    -- Sent in initialize, where the server applies it like a $/setTrace
    trace = 'verbose',
    handlers = {
      ['$/logTrace'] = function(_, params)
        push(
          string.format(
            '%s %s%s',
            os.date('%Y-%m-%d %H:%M:%S '),
            params.message,
            params.verbose or ''
          )
        )
      end,

      ['window/logMessage'] = function(err, params, ctx, cfg)
        local lvl = ({ 'Error', 'Warn', 'Info', 'Log' })[params.type] or tostring(params.type)
        push(string.format('%s [%s] %s', os.date('%Y-%m-%d %H:%M:%S'), lvl, params.message))
        return vim.lsp.handlers['window/logMessage'](err, params, ctx, cfg)
      end,
    },
  },

  setup = function()
    local engine = require('utils.style-enforcers.engine')
    --- @module 'utils.style-enforcers.eslint'
    local eslint = Defer.on_exported_call('utils.style-enforcers.eslint')

    -- The eslint server also attaches to htmlangular (upstream filetypes),
    -- so angular-eslint template fixes should run on save too
    local filetypes = Conf.filetypes.merge(Conf.filetypes.JS_ALL, Conf.filetypes.ANGULAR)
    engine.register_on_attach('eslint', filetypes, eslint.run)

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
    end, {})

    -- `:lsp restart` re-attaches every buffer the old client served
    vim.api.nvim_create_user_command('EslintRestart', 'lsp restart eslint', {})
  end,
}
