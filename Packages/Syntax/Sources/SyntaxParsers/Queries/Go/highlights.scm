;
;  highlights.scm
;  for Go
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; set defaults at first
(identifier) @variables
(field_identifier) @variables


; MARK: Keywords
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


; MARK: Commands
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


; MARK: Types
; ----------------------------

(type_identifier) @types


; MARK: Values
; ----------------------------

[
  (true)
  (false)
  (nil)
  (iota)
] @values


; MARK: Numbers
; ----------------------------

[
  (int_literal)
  (float_literal)
  (imaginary_literal)
] @numbers


; MARK: Strings
; ----------------------------

[
  (interpreted_string_literal)
  (raw_string_literal)
  (rune_literal)
] @strings


; MARK: Characters
; ----------------------------

(escape_sequence) @characters


; MARK: Comments
; ----------------------------

(comment) @comments
