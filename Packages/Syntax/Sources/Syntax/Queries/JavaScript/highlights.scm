;
;  Highlights.scm
;  for JavaScript
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

; built-in functions
((identifier) @commands
 (#eq? @commands "require")
 (#is-not? local))


; Types
; ----------------------------

(class_declaration name: (identifier) @types)
(new_expression constructor: (identifier) @types)

; special identifiers
((identifier) @types
  (#match? @types "^[A-Z][a-z]\\w*$"))


; Attributes
; ----------------------------

; dot-accessed properties
(member_expression
  property: (property_identifier) @attributes)

; keys for object literal
(pair
  key: (property_identifier) @attributes)
; Commands: method-like keys (function-valued properties)
; -> Needs to be placed *after* the definition above.
(pair
  key: (property_identifier) @commands.method
  value: [(function_expression) (arrow_function)])


; Variables
; ----------------------------

; built-in variables (mixed env: JS/Node/Browser)
((identifier) @variables
 (#match? @variables "^(arguments|module|console|window|document|globalThis)$")
 (#is-not? local))
 
; UPPER_SNAKE_CASE identifiers
([
    (identifier)
    (shorthand_property_identifier)
    (shorthand_property_identifier_pattern)
 ] @values
 (#match? @values "^[A-Z_][A-Z\\d_]+$"))
 
[
  (this)
  (super)
] @variables.builtin

; -> Normal variables are set at the beginning of the file.


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

(regex) @strings


; Comments
; ----------------------------

(comment) @comments
