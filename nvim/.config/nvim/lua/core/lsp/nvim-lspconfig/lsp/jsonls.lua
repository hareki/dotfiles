-- The server advertises `json.sort` without an executeCommandProvider, so `Client:exec_cmd` would
-- refuse to send it; a client-side command, which `exec_cmd` checks first, implements it instead
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

        local sorted_lines = vim.split(job.stdout, '\n', { plain = true, trimempty = true })
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, sorted_lines)
      end,
    },
  },
}
