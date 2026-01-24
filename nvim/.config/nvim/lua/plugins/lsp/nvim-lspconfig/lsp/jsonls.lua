-- https://github.com/hrsh7th/vscode-langservers-extracted
-- Doesn't implement the code actions advertised by the server, so we need to manually do it here
local capabilities = {
  ['json.sort'] = function()
    local bufnr = vim.api.nvim_get_current_buf()
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
}

return {
  opts = function()
    return {
      handlers = {
        ['workspace/executeCommand'] = function(_err, _result, ctx, _config)
          local client = vim.lsp.get_client_by_id(ctx.client_id)
          if not client then
            return
          end

          local params = ctx.params
          local command_handler = capabilities[params.command]

          if command_handler then
            command_handler()
            return
          end

          Notifier.error('Unhandled JSON Code Action')
        end,
      },
    }
  end,
}
