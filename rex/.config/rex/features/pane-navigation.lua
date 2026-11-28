-- A program that moves between its own windows gets the key, and hands over to Rex at its edge
-- (nvim: features/navigation/window-navigation). Any other pane moves focus right away

local TERMINAL = 'com.superlogical.terminal'
local NAVIGATION_KEYS = { left = 'm', down = 'n', up = 'e', right = 'i' }
local NAVIGATES_ITSELF = { nvim = true }

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
