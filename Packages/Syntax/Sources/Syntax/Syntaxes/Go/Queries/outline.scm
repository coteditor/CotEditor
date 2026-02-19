;
; outline.scm
; for Go
;
;  CotEditor
;  https://coteditor.com
;
; © 2026 1024jp
;

; Types
(type_spec
  name: (type_identifier) @outline.container
  type: (struct_type))

(type_spec
  name: (type_identifier) @outline.container
  type: (interface_type))

; Functions
(function_declaration
  name: (identifier) @outline.function)

(method_declaration
  name: (field_identifier) @outline.function)
