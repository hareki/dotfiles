return {
  setup = function()
    vim.cmd([[

      " set undercurl color of misspelled / unknown words as diagnostic's
      " highlight! link SpellBad LspDiagnosticsUnderlineHint
      " highlight! link SpellCap LspDiagnosticsUnderlineHint
      " highlight! link SpellRare LspDiagnosticsUnderlineHint
      " highlight! link SpellLocal LspDiagnosticsUnderlineHint


      " remove the undercurl but keep spell checker on to use cmp-spell
      highlight! SpellBad gui=none
      highlight! SpellCap gui=none
      highlight! SpellRare gui=none
      highlight! SpellLocal gui=none


      highlight BufferLineOffsetText gui=bold guibg=#181825

      " remove the background of all floating windows
      highlight! NormalFloat guibg=none

      highlight! Visual cterm=none gui=none

      highlight! link LspReferenceText MyDocumentHighlight
      highlight! link LspReferenceRead MyDocumentHighlight
      highlight! link LspReferenceWrite MyDocumentHighlight

      " Custom highlight groups
      highlight link YankHighlightSystem @comment.warning
      " highlight MyDocumentHighlight guibg=#3b3d4d
      highlight MyDocumentHighlight guibg=#373948

      highlight TreesitterContextBottom gui=none
      highlight TreesitterContext guibg=#373948
  ]])
  end,
}
