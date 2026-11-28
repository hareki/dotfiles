-- pane.close refuses the last pane of a tab. The server closes any pane, and the tab along with its
-- last one

rex.action({
  name = 'close_pane',
  title = 'Close Pane, or the Tab with Its Last Pane',
  run = function(ctx)
    local _, err = rex.call('block.close', { session_id = ctx.session_id, block_id = ctx.block_id })
    if err ~= nil then
      error(err, 0)
    end
  end,
})

-- Rex's own cmd+w closes nvim's buffer here
rex.bind('cmd+d>x', 'close_pane')
