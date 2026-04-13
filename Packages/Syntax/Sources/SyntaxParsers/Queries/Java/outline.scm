;
;  outline.scm
;  for Java
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
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

; Properties
(field_declaration
  declarator: (variable_declarator
    name: (identifier) @outline.value))

; Functions
(method_declaration
  name: (identifier) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)

(constructor_declaration
  name: (identifier) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)
