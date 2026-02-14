; extends

(element) @tag.outer

(script_element) @tag.outer

(style_element) @tag.outer

(element
  (start_tag)
  .
  (_) @tag.inner
  .
  (end_tag))

(element
  (start_tag)
  _+ @tag.inner
  (end_tag))

(script_element
  (start_tag)
  .
  (_) @tag.inner
  .
  (end_tag))

(style_element
  (start_tag)
  .
  (_) @tag.inner
  .
  (end_tag))
