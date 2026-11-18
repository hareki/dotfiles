-- Markdown buffers wrap their lines, and jump between sections in Visual mode too
return {
  'markdown-defaults',
  virtual = true,

  init = function()
    -- markdown.vim's [[ / ]] maps duplicate markdown.lua's, and the double unmap leaves a
    -- silenced E31 in v:errmsg. utils.apply() re-declares the visual-mode pair
    vim.g.no_markdown_maps = 1

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup(
        'features.editing.markdown-defaults.apply',
        { clear = true }
      ),
      pattern = { 'markdown' },
      callback = function(event)
        local utils = require('features.editing.markdown-defaults.utils')
        utils.apply(event.buf)
      end,
    })
  end,
}
