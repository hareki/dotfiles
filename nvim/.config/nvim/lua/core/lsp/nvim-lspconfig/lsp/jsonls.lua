-- The server's Sort JSON action names `json.sort`, a client command (no executeCommandProvider, so
-- `Client:exec_cmd` can't forward it); like VS Code's client, answer it with the server's json/sort
return {
  opts = {
    commands = {
      ['json.sort'] = function(_cmd, ctx)
        local client = vim.lsp.get_client_by_id(ctx.client_id) --[[@as vim.lsp.Client]]
        local bufnr = ctx.bufnr
        local params = {
          uri = vim.uri_from_bufnr(bufnr),
          options = vim.api.nvim_buf_call(bufnr, vim.lsp.util.make_formatting_params).options,
        }

        --- @diagnostic disable-next-line: param-type-mismatch A jsonls method, not in vim.lsp's list
        client:request('json/sort', params, function(err, edits)
          if err then
            Notifier.error('Failed to sort JSON: ' .. err.message)
          elseif edits then
            vim.lsp.util.apply_text_edits(edits, bufnr, client.offset_encoding)
          end
        end, bufnr)
      end,
    },
  },
}
