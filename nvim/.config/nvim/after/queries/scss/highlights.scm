; extends
; nvim-treesitter's scss highlights omit "@apply", as upstream's `apply_statement` couldn't be
; reached from a rule block; the fork makes it reachable, so the keyword needs a capture
"@apply" @keyword
