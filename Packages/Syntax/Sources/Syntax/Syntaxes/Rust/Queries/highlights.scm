;
; Highlights.scm
; for Rust
;
;  CotEditor
;  https://coteditor.com
;
; © 2026 1024jp
;

; Keywords
; ----------------------------

[
  "as"
  "async"
  "await"
  "break"
  "const"
  "continue"
  "default"
  "dyn"
  "else"
  "enum"
  "extern"
  "fn"
  "for"
  "gen"
  "if"
  "impl"
  "in"
  "let"
  "loop"
  "macro_rules!"
  "match"
  "mod"
  "move"
  "pub"
  "raw"
  "ref"
  "return"
  "static"
  "struct"
  "trait"
  "type"
  "union"
  "unsafe"
  "use"
  "where"
  "while"
  "yield"
] @keywords

[
  (crate)
  (mutable_specifier)
  (super)
] @keywords

(use_list (self) @keywords)
(scoped_use_list (self) @keywords)
(scoped_identifier (self) @keywords)


; Commands
; ----------------------------

(call_expression
  function: (identifier) @commands)

(call_expression
  function: (field_expression
    field: (field_identifier) @commands.method))

(call_expression
  function: (scoped_identifier
    name: (identifier) @commands))

(generic_function
  function: (identifier) @commands)

(generic_function
  function: (scoped_identifier
    name: (identifier) @commands))

(generic_function
  function: (field_expression
    field: (field_identifier) @commands.method))

(macro_invocation
  macro: (identifier) @commands)

(function_item (identifier) @commands)
(function_signature_item (identifier) @commands)


; Types
; ----------------------------

(type_identifier) @types
(primitive_type) @types.builtin

((scoped_identifier
  path: (identifier) @types)
 (#match? @types "^[A-Z]"))

((scoped_identifier
  path: (scoped_identifier
    name: (identifier) @types))
 (#match? @types "^[A-Z]"))

((scoped_type_identifier
  path: (identifier) @types)
 (#match? @types "^[A-Z]"))

((scoped_type_identifier
  path: (scoped_identifier
    name: (identifier) @types))
 (#match? @types "^[A-Z]"))

(struct_pattern
  type: (scoped_type_identifier
    name: (type_identifier) @types))


; Attributes
; ----------------------------

[
  (attribute_item)
  (inner_attribute_item)
] @attributes


; Variables
; ----------------------------

(field_identifier) @variables
(parameter (identifier) @variables)

(self) @variables.builtin


; Values
; ----------------------------

(boolean_literal) @values

((identifier) @values
 (#match? @values "^[A-Z][A-Z\\d_]+$"))


; Numbers
; ----------------------------

[
  (integer_literal)
  (float_literal)
] @numbers


; Strings
; ----------------------------

[
  (string_literal)
  (raw_string_literal)
] @strings


; Characters
; ----------------------------

[
  (char_literal)
  (escape_sequence)
] @characters


; Comments
; ----------------------------

[
  (line_comment)
  (block_comment)
] @comments
