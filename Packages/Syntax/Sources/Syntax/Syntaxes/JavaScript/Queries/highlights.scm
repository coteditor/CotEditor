;
; Highlights.scm
; for JavaScript
;
;  CotEditor
;  https://coteditor.com
;
; © 2026 1024jp
;

; set variables at first
(identifier) @variables


; Keywords
; ----------------------------

[
  "as"
  "async"
  "await"
  "break"
  "case"
  "catch"
  "class"
  "const"
  "continue"
  "debugger"
  "default"
  "delete"
  "do"
  "else"
  "export"
  "extends"
  "finally"
  "for"
  "from"
  "function"
  "get"
  "if"
  "import"
  "in"
  "instanceof"
  "let"
  "new"
  "of"
  "return"
  "set"
  "static"
  "switch"
  "target"
  "throw"
  "try"
  "typeof"
  "var"
  "void"
  "while"
  "with"
  "yield"
] @keywords


; Commands
; ----------------------------

; function and method calls
(call_expression
  function: (identifier) @commands)
(call_expression
  function: (member_expression
    property: (property_identifier) @commands.method))


; function and method definitions
(function_expression
  name: (identifier) @commands)
(function_declaration
  name: (identifier) @commands)
(method_definition
  name: (property_identifier) @commands.method)

(pair
  key: (property_identifier) @commands.method
  value: [(function_expression) (arrow_function)])

(assignment_expression
  left: (member_expression
    property: (property_identifier) @commands.method)
  right: [(function_expression) (arrow_function)])

(variable_declarator
  name: (identifier) @commands
  value: [(function_expression) (arrow_function)])

(assignment_expression
  left: (identifier) @commands
  right: [(function_expression) (arrow_function)])


; Types
; ----------------------------

; Special identifiers

((identifier) @constructor
 (#match? @constructor "^[A-Z]"))

([
    (identifier)
    (shorthand_property_identifier)
    (shorthand_property_identifier_pattern)
 ] @constant
 (#match? @constant "^[A-Z_][A-Z\\d_]+$"))

((identifier) @variable.builtin
 (#match? @variable.builtin "^(arguments|module|console|window|document)$")
 (#is-not? local))

((identifier) @function.builtin
 (#eq? @function.builtin "require")
 (#is-not? local))


; Attributes
; ----------------------------

(property_identifier) @attributes


; Variables
; ----------------------------

; Normal variables are set at the beginning of the file.
[
  (this)
  (super)
] @variables.builtin


; Values
; ----------------------------

[
  (true)
  (false)
  (null)
  (undefined)
] @values


; Numbers
; ----------------------------

(number) @numbers


; Strings
; ----------------------------

[
  (string)
  (template_string)
] @strings

(regex) @strings.regex


; Comments
; ----------------------------

(comment) @comments
