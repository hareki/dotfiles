return {
  Catppuccin(function(palette)
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
      local icons = Icons.file_icons

      return {
        file = {
          ['.keep'] = { glyph = icons.keep, hl = 'MiniIconsGrey' },
          ['devcontainer.json'] = { glyph = icons.devcontainer, hl = 'MiniIconsAzure' },

          ['.eslintrc.js'] = { glyph = icons.eslint, hl = 'MiniIconsYellow' },
          ['.node-version'] = { glyph = icons.node_version, hl = 'MiniIconsGreen' },
          ['.prettierrc'] = { glyph = icons.prettierrc, hl = 'MiniIconsPurple' },
          ['.yarnrc.yml'] = { glyph = icons.yarnrc, hl = 'MiniIconsBlue' },
          ['eslint.config.js'] = { glyph = icons.eslint_config, hl = 'MiniIconsYellow' },
          ['package.json'] = { glyph = icons.package_json, hl = 'MiniIconsGreen' },
          ['tsconfig.json'] = { glyph = icons.tsconfig, hl = 'MiniIconsAzure' },
          ['tsconfig.build.json'] = { glyph = icons.tsconfig_build, hl = 'MiniIconsAzure' },
          ['yarn.lock'] = { glyph = icons.yarn_lock, hl = 'MiniIconsBlue' },
        },
        filetype = {
          dotenv = { glyph = icons.dotenv, hl = 'MiniIconsYellow' },
        },
      }
    end,
  },
}
