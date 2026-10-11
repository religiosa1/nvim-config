; extends

; foo.yaml.tmpl -> raw text parsed as yaml (html by default), see set-gotmpl-host-lang! in lua/plugins/lang_go.lua
((text) @injection.content
  (#set-gotmpl-host-lang!)
  (#set! injection.combined))
