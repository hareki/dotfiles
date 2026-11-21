-- Only a program that turns on the kitty keyboard protocol reads the cmd key: zsh gets no bytes for
-- it, and nvim's terminal drops it and types the letter. So nvim, zsh and Claude Code listen for alt
-- keys and escape sequences, and each cmd key here sends one

local TERMINAL = 'com.superlogical.terminal'

-- [[ Keys for the program in the pane ]]
local ALT_KEYS = {
  'f', -- zsh: atuin search
  'r', -- nvim: reload buffer
  's', -- nvim: format and save
  'w', -- nvim: close buffer
  'a', -- nvim: claudecode.nvim toggle
  'p', -- Claude Code model picker, Snacks picker preview toggle
  't', -- nvim: floating terminal
  'g', -- nvim: lazygit
  'space', -- zsh: completion
}

for _, key in ipairs(ALT_KEYS) do
  rex.bind('cmd+' .. key, 'pane.send_key', { key = 'alt+' .. key })
end

-- Claude Code: new line
rex.bind('shift+enter', 'pane.send_key', { key = 'alt+enter' })

rex.action({
  name = 'send_text',
  title = 'Send Text to Pane',
  description = 'Types text into the focused terminal, escape sequences included.',
  args = { data = 'string' },
  run = function(_, args)
    local _, err = rex.block.call(TERMINAL, 'write', { data = args.data })
    if err ~= nil then
      error(err, 0)
    end
  end,
})

-- Sent as bytes. The cmd keys go as the kitty keyboard protocol writes them, so nvim reads the key
-- itself. \27[1;6P is ctrl+shift+f1: pane.send_key encodes that so nvim reads <C-S-F1>, not the
-- <F37> its keymap is on. \27[1;6Y is no key at all
rex.bind('ctrl+shift+y', 'send_text', { data = '\27[1;6Y' }) -- zsh: forward-word
rex.bind('shift+cmd+s', 'send_text', { data = '\27[115;10u' }) -- nvim: <D-S-s>, format and save all
rex.bind('ctrl+m', 'send_text', { data = '\27[1;6P' }) -- nvim: <F37>, multicursor toggle
rex.bind('shift+cmd+w', 'send_text', { data = '\27[119;10u' }) -- nvim: <D-S-w>, close other buffers

-- [[ Pane navigation, shared with nvim ]]
-- A program that moves between its own windows gets the key, and hands over to Rex at its edge
-- (nvim: features/navigation/window-navigation). Any other pane moves focus right away
local NAVIGATION_KEYS = { left = 'm', down = 'n', up = 'e', right = 'i' }
local NAVIGATES_ITSELF = { nvim = true, vim = true, fzf = true }

rex.action({
  name = 'navigate',
  title = 'Go to Pane or Editor Window',
  args = { direction = 'string' },
  run = function(_, args)
    local process = rex.block.call(TERMINAL, 'process', {})
    local foreground = process and process.foreground

    if foreground and NAVIGATES_ITSELF[foreground.name] then
      rex.block.call(TERMINAL, 'write', { data = '\27' .. NAVIGATION_KEYS[args.direction] })
      return
    end

    local _, err = rex.session.focus_direction({ direction = args.direction })
    if err ~= nil then
      error(err, 0)
    end
  end,
})

for direction, key in pairs(NAVIGATION_KEYS) do
  rex.bind('cmd+' .. key, 'navigate', { direction = direction })
end

-- [[ Tabs ]]
rex.bind('cmd+[', 'client.tab.previous')
rex.bind('cmd+]', 'client.tab.next')

-- [[ Prefix: cmd+d ]]
rex.bind('cmd+d>shift+r', 'client.config.reload')

rex.bind('cmd+d>-', 'pane.split', { direction = 'down' })
rex.bind('cmd+d>\\', 'pane.split', { direction = 'right' })
-- Rex's own cmd+w closes nvim's buffer here
rex.bind('cmd+d>x', 'pane.close')
rex.bind('cmd+d>z', 'pane.zoom')
rex.bind('cmd+d>n', 'client.tab.new')
rex.bind('cmd+d>shift+n', 'session.new')
rex.bind('cmd+d>r', 'client.tab.rename')

rex.bind('cmd+d>left', 'client.tab.move.backward')
rex.bind('cmd+d>right', 'client.tab.move.forward')

rex.bind('cmd+d>escape', 'pane.copy_mode.enter')

-- [[ Settings ]]
local SETTINGS = require('settings')
-- A Ghostty theme file, which the import reads. Imported again on every apply: the import replaces
-- the theme of that name
local THEME = os.getenv('HOME') .. '/.config/rex/themes/Catppuccin Mocha'

rex.action({
  name = 'apply_settings',
  title = 'Apply Settings from Dotfiles',
  description = 'Imports the theme file and sets every setting settings.lua lists.',
  run = function()
    rex.client.queue('client.theme.import', { path = THEME })
    for _, setting in ipairs(SETTINGS) do
      rex.client.queue('client.setting.' .. setting[1], { value = setting[2] })
    end
  end,
})
