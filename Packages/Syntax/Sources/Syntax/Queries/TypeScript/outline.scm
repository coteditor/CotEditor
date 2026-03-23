;
;  outline.scm
;  for TypeScript
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
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
  name: (identifier) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)

(method_definition
  name: (property_identifier) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)

(method_definition
  name: (private_property_identifier) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)

(generator_function_declaration
  name: (identifier) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)

(function_signature
  name: (identifier) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)

(method_signature
  name: (property_identifier) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)

(abstract_method_signature
  name: (property_identifier) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)
