return {
  UI.catppuccin(function(palette)
    return { MiniIconsAzure = { fg = palette.teal } }
  end),

  {
    'echasnovski/mini.icons',
    init = function()
      package.preload['nvim-web-devicons'] = function()
        local mini_icons = require('mini.icons')
        mini_icons.mock_nvim_web_devicons()
        return package.loaded['nvim-web-devicons']
      end
    end,

    opts = function()
      local icons = Conf.icons.file_icons

      return {
        extension = {
          dbml = { glyph = icons.SQL, hl = 'MiniIconsAzure' },
          ico = { glyph = icons.ICO, hl = 'MiniIconsGreen' },
          scm = { glyph = icons.SCHEME, hl = 'MiniIconsGrey' },
          mdx = { glyph = icons.MARKDOWN, hl = 'MiniIconsYellow' },
        },
        file = {
          ['.keep'] = { glyph = icons.KEEP, hl = 'MiniIconsGrey' },
          ['devcontainer.json'] = { glyph = icons.DEVCONTAINER, hl = 'MiniIconsAzure' },

          ['.eslintrc.js'] = { glyph = icons.ESLINT, hl = 'MiniIconsYellow' },
          ['.node-version'] = { glyph = icons.NODE_VERSION, hl = 'MiniIconsGreen' },
          ['.prettierrc'] = { glyph = icons.PRETTIERRC, hl = 'MiniIconsPurple' },
          ['.yarnrc.yml'] = { glyph = icons.YARNRC, hl = 'MiniIconsBlue' },
          ['eslint.config.js'] = { glyph = icons.ESLINT_CONFIG, hl = 'MiniIconsYellow' },
          ['package.json'] = { glyph = icons.PACKAGE_JSON, hl = 'MiniIconsGreen' },
          ['tsconfig.json'] = { glyph = icons.TSCONFIG, hl = 'MiniIconsAzure' },
          ['tsconfig.build.json'] = { glyph = icons.TSCONFIG_BUILD, hl = 'MiniIconsAzure' },
          ['yarn.lock'] = { glyph = icons.YARN_LOCK, hl = 'MiniIconsBlue' },
        },
        filetype = {
          env = { glyph = icons.DOTENV, hl = 'MiniIconsYellow' },
          dotenv = { glyph = icons.DOTENV, hl = 'MiniIconsYellow' },
          sql = { glyph = icons.SQL, hl = 'MiniIconsYellow' },
          text = { glyph = icons.TEXT, hl = 'MiniIconsGrey' },
        },
      }
    end,
  },
}
