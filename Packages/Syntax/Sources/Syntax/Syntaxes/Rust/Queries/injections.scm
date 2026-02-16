;
; Injections.scm
; for Rust
;
;  CotEditor
;  https://coteditor.com
;
; © 2026 1024jp
;

((macro_invocation
  (token_tree) @injection.content)
 (#set! injection.language "rust")
 (#set! injection.include-children))

((macro_rule
  (token_tree) @injection.content)
 (#set! injection.language "rust")
 (#set! injection.include-children))
