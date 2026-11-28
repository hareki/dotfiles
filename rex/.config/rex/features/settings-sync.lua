-- A Ghostty theme file, which the import reads. Imported again on every apply: the import replaces
-- the theme of that name
local THEME = os.getenv('HOME') .. '/.config/rex/themes/Catppuccin Mocha'

rex.action({
  name = 'apply_settings',
  title = 'Apply Settings from Dotfiles',
  description = 'Imports the theme file and sets every setting config/settings.lua lists.',
  run = function()
    -- Rex reads config files only on a reload: drop the cache to read settings.lua as edited
    package.loaded['config.settings'] = nil
    local settings = require('config.settings')
    rex.client.queue('client.theme.import', { path = THEME })
    for _, setting in ipairs(settings) do
      rex.client.queue('client.setting.' .. setting[1], { value = setting[2] })
    end
  end,
})
