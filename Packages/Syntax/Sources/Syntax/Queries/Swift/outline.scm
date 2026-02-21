;
;  outline.scm
;  for Swift
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; Containers
(class_declaration
  declaration_kind: "class"
  name: (type_identifier) @outline.container)

(class_declaration
  declaration_kind: "struct"
  name: (type_identifier) @outline.container)

(class_declaration
  declaration_kind: "actor"
  name: (type_identifier) @outline.container)

(class_declaration
  declaration_kind: "enum"
  name: (type_identifier) @outline.container)

(class_declaration
  declaration_kind: "extension"
  name: (_) @outline.container)

(protocol_declaration
  name: (type_identifier) @outline.container)

; Functions
(function_declaration
  (simple_identifier) @outline.function)

(protocol_function_declaration
  name: (simple_identifier) @outline.function)

(subscript_declaration
  "subscript" @outline.function)

(init_declaration
  "init" @outline.function)

(deinit_declaration
  "deinit" @outline.function)

; Values
(property_declaration
  (pattern) @outline.value
  (computed_property))

(protocol_property_declaration
  (pattern (simple_identifier) @outline.value))

; Comment marks
((comment) @outline.separator
  (#match? @outline.separator "^\\s*//\\s*MARK:\\s*-\\s*.*$"))

((multiline_comment) @outline.separator
  (#match? @outline.separator "^\\s*/\\*+\\s*MARK:\\s*-\\s*.*$"))

((comment) @outline.mark
  (#match? @outline.mark "^\\s*//\\s*(MARK:|TODO:|FIXME:)"))

((multiline_comment) @outline.mark
  (#match? @outline.mark "^\\s*/\\*+\\s*(MARK:|TODO:|FIXME:)"))
