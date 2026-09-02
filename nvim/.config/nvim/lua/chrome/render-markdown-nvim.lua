return {
  UI.catppuccin(function(palette)
    local heading_colors = {
      palette.blue,
      palette.yellow,
      palette.green,
      palette.teal,
      palette.mauve,
      palette.lavender,
    }

    local highlights = {
      RenderMarkdownCode = { bg = 'none' },
    }

    for level, color in ipairs(heading_colors) do
      local group = string.format('RenderMarkdownH%d', level)
      local ts_group = string.format('@markup.heading.%d.markdown', level)

      highlights[group] = { fg = color }
      highlights[group .. 'Bg'] = { bg = UI.color.blend_hex(palette.base, color) }
      -- The plugin only colors the icon, the heading text keeps its treesitter highlight
      highlights[ts_group] = { link = group }
    end

    return highlights
  end, 'render-markdown.nvim'),

  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = Conf.filetypes.MARKDOWN,
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' },

    opts = function()
      --- @module 'render-markdown'
      --- @type render.md.UserConfig
      return {
        file_types = Conf.filetypes.MARKDOWN,
        heading = {
          position = 'inline', -- Same indentation for every level, instead of one space per '#'
          width = 'block', -- Background hugs the heading text instead of spanning the window
          left_pad = 1,
          right_pad = 1,
        },
        sign = {
          enabled = false,
        },
        callout = {
          error = {
            rendered = Conf.icons.diagnostics.ERROR .. 'Error',
          },
          hint = {
            highlight = 'RenderMarkdownHint',
          },
        },
        quote = {
          icon = Conf.icons.misc.QUOTE_BAR, -- Thinner line for quotes
        },
      }
    end,
  },
}
