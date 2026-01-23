return {
  'artemave/workspace-diagnostics.nvim',
  keys = {
    {
      '<leader>x',
      function()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        local lines = {}
        for idx, client in ipairs(clients) do
          lines[#lines + 1] = string.format('  %d. %s', idx, client.name)
        end

        local body = #lines > 0 and table.concat(lines, '\n') or 'No clients'

        Notifier.info('Fetching workspace diagnostics from:\n' .. body)
        local workspace_diagnostics = require('workspace-diagnostics')
        for _, client in ipairs(clients) do
          workspace_diagnostics.populate_workspace_diagnostics(client, 0)
        end
      end,

      desc = 'Fetch Workspace Diagnostics',
    },
  },
  opts = {},
}
