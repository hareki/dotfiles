; extends

(element) @tag.outer

(script_element) @tag.outer

(style_element) @tag.outer

(_
  (start_tag)
  _+ @tag.inner
  (end_tag))
