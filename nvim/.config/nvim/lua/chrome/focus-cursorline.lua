-- The cursor line follows the focused window (UI.cursorline); the others keep only its number
return {
  'focus-cursorline',
  virtual = true,
  event = 'VeryLazy',

  init = function()
    vim.opt.cursorline = true
  end,

  config = function()
    UI.cursorline.follow_focus()
  end,
}
