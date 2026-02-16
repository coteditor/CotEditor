;
; outline.scm
; for TypeScript
;
;  CotEditor
;  https://coteditor.com
;
; © 2026 1024jp
;

; Containers
(abstract_class_declaration
  name: (type_identifier) @outline.container)

(class_declaration
  name: (type_identifier) @outline.container)

(interface_declaration
  name: (type_identifier) @outline.container)

(enum_declaration
  name: (identifier) @outline.container)

; Functions
(function_declaration
  name: (identifier) @outline.function)
