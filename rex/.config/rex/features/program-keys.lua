-- Keys for the program in the pane.
-- Only a program that turns on the kitty keyboard protocol reads the cmd key: zsh gets no bytes for
-- it, and nvim's terminal drops it and types the letter. So nvim, zsh and Claude Code listen for alt
-- keys and escape sequences, and each cmd key here sends one

local TERMINAL_WRITE = 'com.superlogical.terminal.write'

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

-- The cmd key itself, which nvim reads through the kitty keyboard protocol. A legacy pane such as
-- zsh gets no bytes for it. A function that returns false hands the key to the pane while still
-- shadowing the app default; a pane.send_key binding that sends its own key reaches no pane
local function pass_through()
  return false
end

rex.bind('shift+cmd+s', pass_through) -- nvim: <D-S-s>, format and save all
rex.bind('shift+cmd+w', pass_through) -- nvim: <D-S-w>, close other buffers

-- Sent as bytes. \27[1;6P is ctrl+shift+f1: pane.send_key encodes that so nvim reads <C-S-F1>, not
-- the <F37> its keymap is on. \27[1;6Y is no key at all
rex.bind('ctrl+shift+y', TERMINAL_WRITE, { data = '\27[1;6Y' }) -- zsh: forward-word
rex.bind('ctrl+m', TERMINAL_WRITE, { data = '\27[1;6P' }) -- nvim: <F37>, multicursor toggle
