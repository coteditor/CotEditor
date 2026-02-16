;
; outline.scm
; for Java
;
;  CotEditor
;  https://coteditor.com
;
; © 2026 1024jp
;

; Containers
(class_declaration
  name: (identifier) @outline.container)

(interface_declaration
  name: (identifier) @outline.container)

(enum_declaration
  name: (identifier) @outline.container)

(record_declaration
  name: (identifier) @outline.container)

; Functions
(method_declaration
  (identifier) @outline.function)

(constructor_declaration
  name: (identifier) @outline.function)
