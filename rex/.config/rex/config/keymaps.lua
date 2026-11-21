-- Keys for Rex's own actions. A key that belongs to a feature is bound in its file under features/

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
