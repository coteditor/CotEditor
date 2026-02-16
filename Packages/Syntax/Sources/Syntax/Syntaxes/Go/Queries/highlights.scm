;
; Highlights.scm
; for Go
;
;  CotEditor
;  https://coteditor.com
;
; © 2026 1024jp
;

; Keywords
; ----------------------------

[
  "break"
  "case"
  "chan"
  "const"
  "continue"
  "default"
  "defer"
  "else"
  "fallthrough"
  "for"
  "func"
  "go"
  "goto"
  "if"
  "import"
  "interface"
  "map"
  "package"
  "range"
  "return"
  "select"
  "struct"
  "switch"
  "type"
  "var"
] @keywords


; Commands
; ----------------------------

(call_expression
  function: (identifier) @commands)

(call_expression
  function: (identifier) @commands.builtin
  (#match? @commands.builtin "^(append|cap|close|complex|copy|delete|imag|len|make|new|panic|print|println|real|recover)$"))

(call_expression
  function: (selector_expression
    field: (field_identifier) @commands.method))

(function_declaration
  name: (identifier) @commands)

(method_declaration
  name: (field_identifier) @commands.method)


; Types
; ----------------------------

(type_identifier) @types


; Attributes
; ----------------------------


; Variables
; ----------------------------

(field_identifier) @variables
(identifier) @variables


; Values
; ----------------------------

[
  (true)
  (false)
  (nil)
  (iota)
] @values


; Numbers
; ----------------------------

[
  (int_literal)
  (float_literal)
  (imaginary_literal)
] @numbers


; Strings
; ----------------------------

[
  (interpreted_string_literal)
  (raw_string_literal)
  (rune_literal)
] @strings


; Characters
; ----------------------------

(escape_sequence) @characters


; Comments
; ----------------------------

(comment) @comments
