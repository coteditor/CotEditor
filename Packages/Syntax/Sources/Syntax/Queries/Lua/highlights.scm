;
;  highlights.scm
;  for Lua
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

"return" @keywords.return

[
  "goto"
  "in"
  "local"
  "global"
] @keywords

(break_statement) @keywords

(do_statement
  [
    "do"
    "end"
  ] @keywords)

(while_statement
  [
    "while"
    "do"
    "end"
  ] @keywords)

(repeat_statement
  [
    "repeat"
    "until"
  ] @keywords)

(if_statement
  [
    "if"
    "elseif"
    "else"
    "then"
    "end"
  ] @keywords)

(elseif_statement
  [
    "elseif"
    "then"
    "end"
  ] @keywords)

(else_statement
  [
    "else"
    "end"
  ] @keywords)

(for_statement
  [
    "for"
    "do"
    "end"
  ] @keywords)

(function_declaration
  [
    "function"
    "end"
  ] @keywords)

(function_definition
  [
    "function"
    "end"
  ] @keywords)

[
  "and"
  "not"
  "or"
] @keywords.operator


; Commands
; ----------------------------

(function_declaration
  name: [
    (identifier) @commands
    (dot_index_expression
      field: (identifier) @commands.method)
  ])

(function_declaration
  name: (method_index_expression
    method: (identifier) @commands.method))

(assignment_statement
  (variable_list
    .
    name: [
      (identifier) @commands
      (dot_index_expression
        field: (identifier) @commands.method)
    ])
  (expression_list
    .
    value: (function_definition)))

(table_constructor
  (field
    name: (identifier) @commands
    value: (function_definition)))

(function_call
  name: [
    (identifier) @commands
    (dot_index_expression
      field: (identifier) @commands.method)
    (method_index_expression
      method: (identifier) @commands.method)
  ])

(function_call
  (identifier) @commands.builtin
  (#any-of? @commands.builtin
    "assert"
    "collectgarbage"
    "dofile"
    "error"
    "getfenv"
    "getmetatable"
    "ipairs"
    "load"
    "loadfile"
    "loadstring"
    "module"
    "next"
    "pairs"
    "pcall"
    "print"
    "rawequal"
    "rawget"
    "rawset"
    "require"
    "select"
    "setfenv"
    "setmetatable"
    "tonumber"
    "tostring"
    "type"
    "unpack"
    "xpcall"
    ; Lua 5.2+
    "rawlen"
    "warn"
  ))


; Types
; ----------------------------

((identifier) @types.constant
 (#match? @types.constant "^[A-Z][A-Z_0-9]*$"))


; Attributes
; ----------------------------

(field
  name: (identifier) @attributes)

(dot_index_expression
  field: (identifier) @attributes)

(variable_list
  (attribute
    (identifier) @attributes))


; Variables
; ----------------------------

((identifier) @variables.builtin
  (#eq? @variables.builtin "self"))

(parameters
  (identifier) @variables)


; Values
; ----------------------------

(vararg_expression) @values

(nil) @values.builtin

[
  (false)
  (true)
] @values.builtin


; Numbers
; ----------------------------

(number) @numbers


; Strings
; ----------------------------

(string) @strings


; Characters
; ----------------------------

(escape_sequence) @characters


; Comments
; ----------------------------

(comment) @comments
(hash_bang_line) @comments
