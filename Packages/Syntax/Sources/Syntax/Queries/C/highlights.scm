;
;  Highlights.scm
;  for C
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; set variables at first
(identifier) @variables


; Keywords
; ----------------------------

[
  "break"
  "case"
  "const"
  "continue"
  "default"
  "do"
  "else"
  "enum"
  "extern"
  "for"
  "if"
  "inline"
  "return"
  "sizeof"
  "static"
  "struct"
  "switch"
  "typedef"
  "union"
  "volatile"
  "while"
] @keywords

[
  "#define"
  "#elif"
  "#else"
  "#endif"
  "#if"
  "#ifdef"
  "#ifndef"
  "#include"
] @keywords

(preproc_directive) @keywords


; Commands
; ----------------------------

(call_expression
  function: (identifier) @commands)

(call_expression
  function: (field_expression
    field: (field_identifier) @commands))

(function_declarator
  declarator: (identifier) @commands)

(preproc_function_def
  name: (identifier) @commands)


; Types
; ----------------------------

[
  (type_identifier)
  (primitive_type)
  (sized_type_specifier)
] @types

(struct_specifier
  name: (type_identifier) @types)

(union_specifier
  name: (type_identifier) @types)

(enum_specifier
  name: (type_identifier) @types)

(type_definition
  declarator: (type_identifier) @types)


; Values
; ----------------------------

((identifier) @values
  (#match? @values "^[A-Z][A-Z\\d_]*$"))

(null) @values.builtin


; Numbers
; ----------------------------

[
  (number_literal)
  (char_literal)
] @numbers


; Strings
; ----------------------------

[
  (string_literal)
  (system_lib_string)
] @strings


; Attributes
; ----------------------------

(field_identifier) @attributes


; Comments
; ----------------------------

(comment) @comments
