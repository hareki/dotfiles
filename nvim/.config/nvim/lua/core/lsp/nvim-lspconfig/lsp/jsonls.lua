-- https://github.com/hrsh7th/vscode-langservers-extracted
-- The server advertises the `json.sort` code action but no executeCommandProvider,
-- so `Client:exec_cmd` would refuse to send it; implement it as a client-side
-- command instead, which `exec_cmd` checks first
return {
  opts = {
    commands = {
      ['json.sort'] = function(_cmd, ctx)
        local bufnr = ctx.bufnr
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local content = table.concat(lines, '\n')

        if vim.fn.executable('jq') == 0 then
          Notifier.warn('jq is not installed. Install it to use JSON sorting.')
          return
        end

        -- Use jq to sort the JSON
        local job = vim
          .system({ 'jq', '-S', '.' }, {
            stdin = content,
            text = true,
          })
          :wait()

        if job.code ~= 0 then
          Notifier.error('Failed to sort JSON: ' .. (job.stderr or 'Unknown error'))
          return
        end

        -- Replace buffer content with sorted JSON
        local sorted_lines = vim.split(job.stdout, '\n', { plain = true, trimempty = true })
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, sorted_lines)
      end,
    },
  },
}
