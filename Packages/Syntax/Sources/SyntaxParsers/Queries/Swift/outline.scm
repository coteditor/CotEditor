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
  name: (simple_identifier) @outline.function
  "("
  .
  ")" @outline.signature.end)

(function_declaration
  name: (simple_identifier) @outline.function
  "("
  (parameter) @outline.signature.parameter
  ("," (parameter) @outline.signature.parameter)*
  ","?
  ")" @outline.signature.end)

(protocol_function_declaration
  name: (simple_identifier) @outline.function
  "("
  .
  ")" @outline.signature.end)

(protocol_function_declaration
  name: (simple_identifier) @outline.function
  "("
  (parameter) @outline.signature.parameter
  ("," (parameter) @outline.signature.parameter)*
  ","?
  ")" @outline.signature.end)

(subscript_declaration
  "subscript" @outline.function
  "("
  .
  ")" @outline.signature.end)

(subscript_declaration
  "subscript" @outline.function
  "("
  (parameter) @outline.signature.parameter
  ("," (parameter) @outline.signature.parameter)*
  ","?
  ")" @outline.signature.end)

(init_declaration
  "init" @outline.function
  "("
  .
  ")" @outline.signature.end)

(init_declaration
  "init" @outline.function
  "("
  (parameter) @outline.signature.parameter
  ("," (parameter) @outline.signature.parameter)*
  ","?
  ")" @outline.signature.end)

(deinit_declaration
  "deinit" @outline.function)

; Values
(class_body
  (property_declaration
    name: (pattern
      (simple_identifier) @outline.name) @outline.value))

(enum_class_body
  (property_declaration
    name: (pattern
      (simple_identifier) @outline.name) @outline.value))

(protocol_property_declaration
  name: (pattern
    (simple_identifier) @outline.name) @outline.value)

; Comment marks
((comment) @outline.separator
  (#match? @outline.separator "^\\s*//\\s*MARK:\\s*-\\s*.*$"))

((multiline_comment) @outline.separator
  (#match? @outline.separator "^\\s*/\\*+\\s*MARK:\\s*-\\s*.*$"))

((comment) @outline.mark
  (#match? @outline.mark "^\\s*//\\s*(MARK:|TODO:|FIXME:)"))

((multiline_comment) @outline.mark
  (#match? @outline.mark "^\\s*/\\*+\\s*(MARK:|TODO:|FIXME:)"))
