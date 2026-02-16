;
; outline.scm
; for JavaScript
;
;  CotEditor
;  https://coteditor.com
;
; © 2026 1024jp
;

; Containers
(class_declaration
  name: (identifier) @outline.container)

; Functions
(function_declaration
  name: (identifier) @outline.function)

(method_definition
  name: (property_identifier) @outline.function)

(method_definition
  name: (private_property_identifier) @outline.function)
