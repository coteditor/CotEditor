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

; Properties
(field_definition
  property: (property_identifier) @outline.value)

(field_definition
  property: (private_property_identifier) @outline.value)

; Functions
(function_declaration
  name: (identifier) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)

(generator_function_declaration
  name: (identifier) @outline.function
  parameters: (formal_parameters) @outline.signature.parameters)

(method_definition
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
