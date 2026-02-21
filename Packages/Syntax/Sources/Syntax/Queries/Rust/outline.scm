;
;  outline.scm
;  for Rust
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; Containers
(struct_item
  name: (type_identifier) @outline.container)

(enum_item
  name: (type_identifier) @outline.container)

(trait_item
  name: (type_identifier) @outline.container)

(union_item
  name: (type_identifier) @outline.container)

(impl_item
  type: (type_identifier) @outline.container)

; Functions
(function_item
  name: (identifier) @outline.function)

(function_signature_item
  name: (identifier) @outline.function)
