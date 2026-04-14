;
;  outline.scm
;  for PHP
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; Containers
(class_declaration
  name: (name) @outline.container)

(interface_declaration
  name: (name) @outline.container)

(trait_declaration
  name: (name) @outline.container)

(enum_declaration
  name: (name) @outline.container)

; Properties
(property_declaration
  (property_element
    (variable_name) @outline.value))

; Functions
(function_definition
  name: (name) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)

(method_declaration
  name: (name) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)
