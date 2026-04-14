;
;  outline.scm
;  for C++
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; Containers
(class_specifier
  name: (type_identifier) @outline.container
  body: (field_declaration_list))

(struct_specifier
  name: (type_identifier) @outline.container
  body: (field_declaration_list))

(union_specifier
  name: (type_identifier) @outline.container
  body: (field_declaration_list))

(enum_specifier
  name: (type_identifier) @outline.container
  body: (enumerator_list))

(namespace_definition
  name: (namespace_identifier) @outline.container)

; Concepts
(concept_definition
  name: (identifier) @outline.value)

; Properties
(field_declaration
  declarator: [
    (field_identifier) @outline.value
    (pointer_declarator
      declarator: [
        (field_identifier) @outline.value
        (pointer_declarator
          declarator: (field_identifier) @outline.value)
        (reference_declarator
          (field_identifier) @outline.value)
        (array_declarator
          declarator: (field_identifier) @outline.value)
      ])
    (reference_declarator
      [
        (field_identifier) @outline.value
        (pointer_declarator
          declarator: (field_identifier) @outline.value)
      ])
    (array_declarator
      declarator: [
        (field_identifier) @outline.value
        (pointer_declarator
          declarator: (field_identifier) @outline.value)
        (array_declarator
          declarator: (field_identifier) @outline.value)
      ])
  ])

; Functions
(function_definition
  declarator: [
    (function_declarator) @outline.function
    (pointer_declarator
      declarator: [
        (function_declarator) @outline.function
        (pointer_declarator
          declarator: (function_declarator) @outline.function)
      ])
    (reference_declarator
      (function_declarator) @outline.function)
  ])
