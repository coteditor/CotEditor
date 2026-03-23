;
;  outline.scm
;  for Scala
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; Containers
(package_clause
  name: (package_identifier) @outline.container)

(trait_definition
  name: (identifier) @outline.container)

(enum_definition
  name: (identifier) @outline.container)

(class_definition
  name: (identifier) @outline.container)

(object_definition
  name: (identifier) @outline.container)

(type_definition
  name: (type_identifier) @outline.container)

; Functions
(function_definition
  name: [
    (identifier)
    (operator_identifier)
  ] @outline.function
  [
    (type_parameters) @outline.signature.type_parameters
    (parameters) @outline.signature.parameters
  ]*)

(function_declaration
  name: [
    (identifier)
    (operator_identifier)
  ] @outline.function
  [
    (type_parameters) @outline.signature.type_parameters
    (parameters) @outline.signature.parameters
  ]*)

; Values
(val_definition
  pattern: (identifier) @outline.value)

(given_definition
  name: (identifier) @outline.value)

(var_definition
  pattern: (identifier) @outline.value)

(val_declaration
  name: (identifier) @outline.value)

(var_declaration
  name: (identifier) @outline.value)
