return {
  'stevearc/conform.nvim',
  keys = {
    {
      '<A-s>',
      function()
        local style_enforcers = require('features.formatting.conform-nvim.style-enforcers')
        style_enforcers.run()
      end,
      mode = { 'n', 'i' },
      desc = 'Format and Save',
    },
    {
      '<leader>F',
      function()
        local style_enforcers = require('features.formatting.conform-nvim.style-enforcers')
        style_enforcers.run({
          save = false,
        })
      end,
      desc = 'Format',
    },
    -- Sent for Cmd+Shift+S by the ghostty config; inspect with :echo keytrans(getcharstr())
    {
      '<F40>',
      function()
        local style_enforcers = require('features.formatting.conform-nvim.style-enforcers')
        style_enforcers.run_all()
      end,
      mode = { 'n', 'i' },
      desc = 'Format and Save All',
    },
  },
  opts = function()
    local opts = {
      formatters_by_ft = {
        lua = { 'stylua' },
        toml = { 'taplo' },

        -- prettier's glimmer parser breaks Express handlebars, so the html server formats it
        handlebars = { lsp_format = 'fallback' },
      },

      formatters = {
        prettier = {
          -- prettier infers angular only for *.component.html; html mangles app.html's @if/@for
          options = { ft_parsers = { htmlangular = 'angular' } },
          -- oxfmt projects format through its server (style-enforcers/oxfmt.lua), leaving the
          -- filetypes it doesn't serve (lsp/oxfmt.lua) unformatted rather than prettier-styled
          condition = function(_, ctx)
            local in_oxfmt_project = false
            vim.lsp.config.oxfmt.root_dir(ctx.buf, function(root)
              in_oxfmt_project = root ~= nil
            end)
            return not in_oxfmt_project
          end,
        },
      },
    }

    local prettier_filetypes = Conf.filetypes.merge(
      Conf.filetypes.JS_ALL,
      Conf.filetypes.CSS,
      { 'html' },
      Conf.filetypes.ANGULAR,
      Conf.filetypes.MARKDOWN,
      Conf.filetypes.JSON,
      { 'yaml' }
    )
    for _, ft in ipairs(prettier_filetypes) do
      opts.formatters_by_ft[ft] = { 'prettier' }
    end

    return opts
  end,
}
