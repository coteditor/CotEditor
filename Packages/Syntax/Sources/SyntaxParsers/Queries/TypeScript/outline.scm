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

(module
  name: (_) @outline.container)

(internal_module) @outline.container

; Properties
(public_field_definition
  name: (property_identifier) @outline.value)

(public_field_definition
  name: (private_property_identifier) @outline.value)

(property_signature
  name: (property_identifier) @outline.value)

(type_alias_declaration
  name: (type_identifier) @outline.value)

; Functions
(function_declaration
  name: (identifier) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)

(method_definition
  name: (_) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)

(generator_function_declaration
  name: (identifier) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)

(function_signature
  name: (identifier) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)

(method_signature
  name: (_) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)

(abstract_method_signature
  name: (_) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)

; Top-level assigned callables
(program
  [
    (lexical_declaration
      (variable_declarator
        name: (identifier) @outline.function
        value: [
          (arrow_function)
          (function_expression)
          (generator_function)
        ]))
    (variable_declaration
      (variable_declarator
        name: (identifier) @outline.function
        value: [
          (arrow_function)
          (function_expression)
          (generator_function)
        ]))
  ])

(export_statement
  declaration: [
    (lexical_declaration
      (variable_declarator
        name: (identifier) @outline.function
        value: [
          (arrow_function)
          (function_expression)
          (generator_function)
        ]))
    (variable_declaration
      (variable_declarator
        name: (identifier) @outline.function
        value: [
          (arrow_function)
          (function_expression)
          (generator_function)
        ]))
  ])
