; extends

; foo.html.tmpl -> raw text parsed as html, see set-gotmpl-host-lang! in lua/plugins/lang_go.lua
((text) @injection.content
  (#set-gotmpl-host-lang!)
  (#set! injection.combined))
