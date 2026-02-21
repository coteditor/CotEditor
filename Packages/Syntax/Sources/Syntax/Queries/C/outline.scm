;
;  outline.scm
;  for C
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; Containers
(struct_specifier
  name: (type_identifier) @outline.container
  body: (field_declaration_list))

(union_specifier
  name: (type_identifier) @outline.container
  body: (field_declaration_list))

(enum_specifier
  name: (type_identifier) @outline.container
  body: (enumerator_list))

; Functions
(function_definition
  declarator: (function_declarator) @outline.function)

(function_definition
  declarator: (pointer_declarator
    declarator: (function_declarator) @outline.function))
