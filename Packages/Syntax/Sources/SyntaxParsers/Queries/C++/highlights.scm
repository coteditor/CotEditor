;
;  highlights.scm
;  for C++
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
  "alignas"
  "alignof"
  "asm"
  "break"
  "case"
  "catch"
  "class"
  "co_await"
  "co_return"
  "co_yield"
  "concept"
  "const"
  "consteval"
  "constexpr"
  "constinit"
  "continue"
  "decltype"
  "default"
  "delete"
  "do"
  "else"
  "enum"
  "explicit"
  "extern"
  "final"
  "for"
  "friend"
  "goto"
  "if"
  "inline"
  "mutable"
  "namespace"
  "new"
  "noexcept"
  "operator"
  "override"
  "private"
  "protected"
  "public"
  "register"
  "requires"
  "return"
  "sizeof"
  "static"
  "static_assert"
  "struct"
  "switch"
  "template"
  "thread_local"
  "throw"
  "try"
  "typedef"
  "typename"
  "union"
  "using"
  "virtual"
  "volatile"
  "while"
] @keywords

; alternative operator representations
[
  "and"
  "and_eq"
  "bitand"
  "bitor"
  "compl"
  "not"
  "not_eq"
  "or"
  "or_eq"
  "xor"
  "xor_eq"
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

(auto) @keywords
(this) @keywords

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

(call_expression
  function: (qualified_identifier
    name: (identifier) @commands))

(call_expression
  function: (template_function
    name: (identifier) @commands))

(function_declarator
  declarator: (identifier) @commands)

(function_declarator
  declarator: (qualified_identifier
    name: (identifier) @commands))

(function_declarator
  declarator: (field_identifier) @commands)

(preproc_function_def
  name: (identifier) @commands)


; MARK: Types
; ----------------------------

[
  (type_identifier)
  (primitive_type)
  (sized_type_specifier)
] @types

(class_specifier
  name: (type_identifier) @types)

(struct_specifier
  name: (type_identifier) @types)

(union_specifier
  name: (type_identifier) @types)

(enum_specifier
  name: (type_identifier) @types)

(type_definition
  declarator: (type_identifier) @types)

(namespace_identifier) @types


; MARK: Values
; ----------------------------

[
  (null)
  (true)
  (false)
] @values

"nullptr" @values


; MARK: Numbers
; ----------------------------

(number_literal) @numbers


; MARK: Strings
; ----------------------------

[
  (string_literal)
  (raw_string_literal)
  (system_lib_string)
] @strings


; MARK: Characters
; ----------------------------

(char_literal) @characters

(escape_sequence) @characters


; MARK: Comments
; ----------------------------

(comment) @comments
