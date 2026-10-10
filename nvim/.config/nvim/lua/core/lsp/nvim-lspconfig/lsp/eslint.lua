-- Ring buffer: the oldest line drops out once full, in O(1)
local log = vim.ringbuf(200)

--- @param line string
local function push(line)
  log:push((line:gsub('\n', ' ')))
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
        local lvl = vim.lsp.protocol.MessageType[params.type] or tostring(params.type)
        push(string.format('%s [%s] %s', os.date('%Y-%m-%d %H:%M:%S'), lvl, params.message))
        return vim.lsp.handlers['window/logMessage'](err, params, ctx, cfg)
      end,
    },
  },

  setup = function()
    vim.api.nvim_create_user_command('EslintLog', function()
      -- Iterating a ringbuf pops it, oldest first, so push the lines back for the next :EslintLog
      local lines = {}
      for line in log do
        lines[#lines + 1] = line
      end
      for _, line in ipairs(lines) do
        log:push(line)
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
