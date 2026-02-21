;
;  Highlights.scm
;  for Scala
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; Keywords
; ----------------------------

[
  "abstract"
  "case"
  "catch"
  "class"
  "def"
  "derives"
  "do"
  "else"
  "end"
  "enum"
  "export"
  "extends"
  "extension"
  "finally"
  "for"
  "given"
  "if"
  "implicit"
  "import"
  "match"
  "new"
  "object"
  "opaque"
  "override"
  "package"
  "private"
  "protected"
  "return"
  "sealed"
  "then"
  "throw"
  "trait"
  "try"
  "type"
  "using"
  "val"
  "var"
  "while"
  "with"
  "yield"
] @keywords

[
  (opaque_modifier)
  (infix_modifier)
  (transparent_modifier)
  (open_modifier)
  (inline_modifier)
] @keywords


; Commands
; ----------------------------

(function_declaration
  name: (identifier) @commands)

(function_definition
  name: (identifier) @commands)

(call_expression
  function: (identifier) @commands)

(call_expression
  function: (operator_identifier) @commands)

(call_expression
  function: (field_expression
    field: (identifier) @commands))

(generic_function
  function: (identifier) @commands)

(interpolated_string_expression
  interpolator: (identifier) @commands)


; Types
; ----------------------------

(type_identifier) @types

(class_definition
  name: (identifier) @types)

(enum_definition
  name: (identifier) @types)

(object_definition
  name: (identifier) @types)

(trait_definition
  name: (identifier) @types)

(full_enum_case
  name: (identifier) @types)

(simple_enum_case
  name: (identifier) @types)

(type_definition
  name: (type_identifier) @types)

(field_expression
  value: (identifier) @types
  (#match? @types "^[A-Z]"))

; Attributes
; ----------------------------

(annotation) @attributes


; Variables
; ----------------------------

(class_parameter
  name: (identifier) @variables)

(parameter
  name: (identifier) @variables)

(binding
  name: (identifier) @variables)

(self_type
  (identifier) @variables)

(val_definition
  pattern: (identifier) @variables)

(var_definition
  pattern: (identifier) @variables)

(val_declaration
  name: (identifier) @variables)

(var_declaration
  name: (identifier) @variables)


; Values
; ----------------------------

[
  (boolean_literal)
  (null_literal)
] @values

((identifier) @values
  (#match? @values "^this$|^super$"))


; Numbers
; ----------------------------

[
  (integer_literal)
  (floating_point_literal)
] @numbers


; Strings
; ----------------------------

[
  (string)
  (character_literal)
  (interpolated_string_expression)
] @strings


; Characters
; ----------------------------

(interpolation "$" @characters)


; Comments
; ----------------------------

[
  (comment)
  (block_comment)
] @comments
