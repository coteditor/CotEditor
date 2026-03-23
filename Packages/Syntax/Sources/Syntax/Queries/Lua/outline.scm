;
;  outline.scm
;  for Lua
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; Functions
(function_declaration
  name: [
    (identifier) @outline.function
    (dot_index_expression
      field: (identifier) @outline.function)
  ]
  parameters: (parameters) @outline.signature.parameters)

(function_declaration
  name: (method_index_expression
    method: (identifier) @outline.function)
  parameters: (parameters) @outline.signature.parameters)

(assignment_statement
  (variable_list
    .
    name: [
      (identifier) @outline.function
      (dot_index_expression
        field: (identifier) @outline.function)
    ])
  (expression_list
    .
    value: (function_definition
      parameters: (parameters) @outline.signature.parameters)))

(table_constructor
  (field
    name: (identifier) @outline.function
    value: (function_definition
      parameters: (parameters) @outline.signature.parameters)))
