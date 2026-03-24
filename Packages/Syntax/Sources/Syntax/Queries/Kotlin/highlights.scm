;
;  highlights.scm
;  for Kotlin
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; MARK: Keywords
; ----------------------------

[
  "as"
  "break"
  "by"
  "catch"
  "class"
  "companion"
  "constructor"
  "continue"
  "do"
  "else"
  "enum"
  "finally"
  "for"
  "fun"
  "get"
  "if"
  "import"
  "in"
  "init"
  "interface"
  "is"
  "object"
  "package"
  "return"
  "set"
  "throw"
  "try"
  "typealias"
  "val"
  "var"
  "when"
  "where"
  "while"
] @keywords

[
  (class_modifier)
  (member_modifier)
  (function_modifier)
  (property_modifier)
  (inheritance_modifier)
  (parameter_modifier)
  (reification_modifier)
  (visibility_modifier)
] @keywords


; MARK: Commands
; ----------------------------

(function_declaration
  (simple_identifier) @commands)

(call_expression
  (simple_identifier) @commands)

(call_expression
  (navigation_expression
    (navigation_suffix
      (simple_identifier) @commands)))


; MARK: Types
; ----------------------------

(type_identifier) @types

(class_declaration
  (type_identifier) @types)

(object_declaration
  (type_identifier) @types)

((simple_identifier) @types
  (#match? @types "^[A-Z]"))


; MARK: Attributes
; ----------------------------

(annotation
  (user_type
    (type_identifier) @attributes))

(file_annotation
  (user_type
    (type_identifier) @attributes))

"@" @attributes


; MARK: Variables
; ----------------------------

(parameter
  (simple_identifier) @variables)

(class_parameter
  (simple_identifier) @variables)

(property_declaration
  (variable_declaration
    (simple_identifier) @variables))


; MARK: Values
; ----------------------------

(enum_entry
  (simple_identifier) @values)

(boolean_literal) @values

"null" @values


; MARK: Numbers
; ----------------------------

[
  (integer_literal)
  (long_literal)
  (hex_literal)
  (bin_literal)
  (real_literal)
] @numbers


; MARK: Strings
; ----------------------------

[
  (string_literal)
] @strings


; MARK: Characters
; ----------------------------

[
  (character_literal)
(character_escape_seq)
] @characters


; MARK: Comments
; ----------------------------

[
  (line_comment)
  (multiline_comment)
] @comments
