;
;  outline.scm
;  for C#
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; Containers
(namespace_declaration
  name: (_) @outline.container)

(class_declaration
  name: (identifier) @outline.container)

(interface_declaration
  name: (identifier) @outline.container)

(struct_declaration
  name: (identifier) @outline.container)

(record_declaration
  name: (identifier) @outline.container)

(enum_declaration
  name: (identifier) @outline.container)

; Functions
(method_declaration
  name: (identifier) @outline.function)

(local_function_statement
  name: (identifier) @outline.function)

(constructor_declaration
  name: (identifier) @outline.function)

(destructor_declaration
  name: (identifier) @outline.function)
