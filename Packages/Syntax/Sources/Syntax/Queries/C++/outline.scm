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

; Functions
(function_definition
  declarator: [
    (function_declarator)
    (pointer_declarator)
    (reference_declarator)
  ] @outline.function)
