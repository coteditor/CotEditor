;
;  highlights.scm
;  for TypeScript
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; set defaults at first
(identifier) @variables
(property_identifier) @attributes

; UPPER_SNAKE_CASE identifiers
([
    (identifier)
    (shorthand_property_identifier)
    (shorthand_property_identifier_pattern)
 ] @values
 (#match? @values "^[A-Z_][A-Z\\d_]+$"))


; MARK: Keywords
; ----------------------------

[
  "abstract"
  "as"
  "asserts"
  "async"
  "await"
  "break"
  "case"
  "catch"
  "class"
  "const"
  "continue"
  "debugger"
  "declare"
  "default"
  "delete"
  "do"
  "else"
  "enum"
  "export"
  "extends"
  "finally"
  "for"
  "from"
  "function"
  "get"
  "global"
  "if"
  "implements"
  "import"
  "in"
  "infer"
  "instanceof"
  "interface"
  "is"
  "keyof"
  "let"
  "module"
  "namespace"
  "new"
  "of"
  "override"
  "private"
  "protected"
  "public"
  "readonly"
  "return"
  "satisfies"
  "set"
  "static"
  "switch"
  "throw"
  "try"
  "type"
  "typeof"
  "using"
  "var"
  "void"
  "while"
  "with"
  "yield"
] @keywords


; MARK: Commands
; ----------------------------

; function and method calls
(call_expression
  function: (identifier) @commands)
(call_expression
  function: (member_expression
    property: (property_identifier) @commands))

; function and method definitions
(function_expression
  name: (identifier) @commands)
(function_declaration
  name: (identifier) @commands)
(method_definition
  name: (property_identifier) @commands)

(assignment_expression
  left: (member_expression
    property: (property_identifier) @commands)
  right: [(function_expression) (arrow_function)])

(variable_declarator
  name: (identifier) @commands
  value: [(function_expression) (arrow_function)])

(assignment_expression
  left: (identifier) @commands
  right: [(function_expression) (arrow_function)])


; MARK: Types
; ----------------------------

(type_identifier) @types
(predefined_type) @types
(new_expression constructor: (identifier) @types)

; special identifiers
((identifier) @types
  (#match? @types "^[A-Z][a-z]\\w*$"))


; MARK: Attributes
; ----------------------------

; decorators
(decorator
  (identifier) @attributes)
(decorator
  (call_expression
    function: (identifier) @attributes))

; method-like keys (function-valued properties)
(pair
  key: (property_identifier) @commands
  value: [(function_expression) (arrow_function)])


; MARK: Variables
; ----------------------------

((required_parameter (identifier) @variables)
 (#not-match? @variables "^[A-Z_][A-Z\\d_]+$"))
((optional_parameter (identifier) @variables)
 (#not-match? @variables "^[A-Z_][A-Z\\d_]+$"))

; built-in variables (mixed env: JS/Node/Browser)
((identifier) @variables
 (#match? @variables "^(arguments|module|console|window|document|globalThis)$"))

[
  (this)
  (super)
] @variables


; MARK: Values
; ----------------------------

[
  (true)
  (false)
  (null)
  (undefined)
] @values


; MARK: Numbers
; ----------------------------

(number) @numbers


; MARK: Strings
; ----------------------------

[
  (string)
  (template_string)
] @strings

(regex) @strings


; MARK: Comments
; ----------------------------

(comment) @comments
