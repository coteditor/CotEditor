;
;  highlights.scm
;  for C
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; set defaults at first
(identifier) @variables
(field_identifier) @attributes
((identifier) @values
  (#match? @values "^[A-Z][A-Z\\d_]*$"))


; MARK: Keywords
; ----------------------------

[
  "auto"
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
  "goto"
  "if"
  "inline"
  "register"
  "restrict"
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

; C11 keywords and compiler extensions
[
  "_Alignas"
  "_Alignof"
  "_Atomic"
  "_Generic"
  "_Noreturn"
  "__alignof"
  "__alignof__"
  "__asm"
  "__asm__"
  "__attribute"
  "__attribute__"
  "__declspec"
  "__extension__"
  "__forceinline"
  "__inline"
  "__inline__"
  "__restrict__"
  "__thread"
  "__volatile__"
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
  "defined"
] @keywords

(preproc_directive) @keywords


; MARK: Commands
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


; MARK: Types
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


; MARK: Values
; ----------------------------

(null) @values.builtin


; MARK: Numbers
; ----------------------------

(number_literal) @numbers


; MARK: Strings
; ----------------------------

[
  (string_literal)
  (system_lib_string)
] @strings


; MARK: Characters
; ----------------------------

(char_literal) @characters


; MARK: Comments
; ----------------------------

(comment) @comments
