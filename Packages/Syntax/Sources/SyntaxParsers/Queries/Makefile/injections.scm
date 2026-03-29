;
;  Injections.scm
;  for Makefile
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

((recipe_line
  (shell_text) @injection.content)
 (#set! injection.language "bash"))
