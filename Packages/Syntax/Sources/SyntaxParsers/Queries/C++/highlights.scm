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


; MARK: Keywords
; ----------------------------

[
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
  "return"
  "sizeof"
  "static"
  "struct"
  "switch"
  "template"
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

((identifier) @values
  (#match? @values "^[A-Z][A-Z\\d_]*$"))

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
