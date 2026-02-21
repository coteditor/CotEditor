;
;  Injections.scm
;  for HTML
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

((script_element
  (raw_text) @injection.content)
 (#set! injection.language "javascript"))

((style_element
  (raw_text) @injection.content)
 (#set! injection.language "css"))
