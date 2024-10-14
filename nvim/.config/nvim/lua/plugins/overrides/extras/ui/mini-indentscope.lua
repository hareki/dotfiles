local indentscope = require("mini.indentscope")

return {
  {
    "echasnovski/mini.indentscope",
    opts = {
      draw = {
        delay = 0,
        animation = indentscope.gen_animation.none(),
      },
    },
  },
}
