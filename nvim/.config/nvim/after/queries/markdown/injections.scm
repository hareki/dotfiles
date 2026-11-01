; extends
((inline) @injection.content
  (#match? @injection.content "^\\s*(import|export)")
  (#set! injection.language "typescript"))
