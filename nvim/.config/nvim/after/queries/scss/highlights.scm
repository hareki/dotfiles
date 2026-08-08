; extends
; nvim-treesitter's scss highlights list every other SCSS at-keyword but omit
; "@apply", because upstream's `apply_statement` was unreachable from inside a
; rule block. The fork makes it reachable, so the keyword needs a capture.
"@apply" @keyword
