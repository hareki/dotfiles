-- Keys for the program in the pane.
-- Only a program that turns on the kitty keyboard protocol reads the cmd key: zsh gets no bytes for
-- it, and nvim's terminal drops it and types the letter. So nvim, zsh and Claude Code listen for alt
-- keys and escape sequences, and each cmd key here sends one

local TERMINAL = 'com.superlogical.terminal'

local ALT_KEYS = {
  'f', -- zsh: atuin search
  'r', -- nvim: reload buffer
  's', -- nvim: format and save
  'w', -- nvim: close buffer
  'a', -- nvim: claudecode.nvim toggle
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
