;
;  outline.scm
;  for JavaScript
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; Containers
(class_declaration
  name: (identifier) @outline.container)

; Functions
(function_declaration
  name: (identifier) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)

(generator_function_declaration
  name: (identifier) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)

(method_definition
  name: (property_identifier) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)

(method_definition
  name: (private_property_identifier) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)
