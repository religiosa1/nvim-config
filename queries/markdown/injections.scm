; Full replacement of the default markdown injections (NOT `; extends`), because
; we must override the built-in html_block->html injection, which injects html
; over the block's *entire* text and derails on Observable ${...} JavaScript.
; See plugin/observable-interp.lua for the ${...} scanning logic.

; --- defaults, copied verbatim from $VIMRUNTIME/queries/markdown/injections.scm ---

(fenced_code_block
  (info_string
    (language) @injection.language)
  (code_fence_content) @injection.content)

((minus_metadata) @injection.content
  (#set! injection.language "yaml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

((plus_metadata) @injection.content
  (#set! injection.language "toml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

([
  (inline)
  (pipe_table_cell)
] @injection.content
  (#set! injection.language "markdown_inline"))

; --- Observable: html carved around ${...}, and JS inside each ${...} ---
; Anchor per line: the html_block node stands in for its first line, each
; block_continuation for a following line. obs-html! trims each line to its
; JS-free span; combined merges the fragments into one clean html parse.

; One pattern so `combined` merges every fragment into a single html parse
; (split patterns would each combine separately, orphaning close tags from their
; openers). html_block stands in for the block's first line, block_continuation
; for the rest. include-children keeps our trimmed range intact -- without it,
; get_node_ranges masks html_block's block_continuation children back out,
; re-injecting the (JS-carrying) per-line spans.
([
  (html_block)
  (block_continuation)
] @injection.content
  (#obs-html? @injection.content)
  (#obs-html! @injection.content)
  (#set! injection.language "html")
  (#set! injection.combined)
  (#set! injection.include-children))

((block_continuation) @injection.content
  (#obs-js? @injection.content)
  (#obs-js! @injection.content)
  (#set! injection.language "javascript"))
