;
; Highlights.scm
; for Java
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
  "abstract"
  "assert"
  "break"
  "case"
  "catch"
  "class"
  "continue"
  "default"
  "do"
  "else"
  "enum"
  "exports"
  "extends"
  "final"
  "finally"
  "for"
  "if"
  "implements"
  "import"
  "instanceof"
  "interface"
  "module"
  "native"
  "new"
  "non-sealed"
  "open"
  "opens"
  "package"
  "permits"
  "private"
  "protected"
  "provides"
  "public"
  "requires"
  "record"
  "return"
  "sealed"
  "static"
  "strictfp"
  "switch"
  "synchronized"
  "throw"
  "throws"
  "to"
  "transient"
  "transitive"
  "try"
  "uses"
  "volatile"
  "when"
  "while"
  "with"
  "yield"
  (this)
  (super)
] @keywords


; Commands
; ----------------------------

(method_declaration
  name: (identifier) @commands.method)

(method_invocation
  name: (identifier) @commands.method)


; Types
; ----------------------------

(type_identifier) @types

(interface_declaration
  name: (identifier) @types)

(class_declaration
  name: (identifier) @types)

(enum_declaration
  name: (identifier) @types)

((field_access
  object: (identifier) @types)
 (#match? @types "^[A-Z]"))

((scoped_identifier
  scope: (identifier) @types)
 (#match? @types "^[A-Z]"))

((method_invocation
  object: (identifier) @types)
 (#match? @types "^[A-Z]"))

((method_reference
  . (identifier) @types)
 (#match? @types "^[A-Z]"))

(constructor_declaration
  name: (identifier) @types)

[
  (boolean_type)
  (integral_type)
  (floating_point_type)
  (void_type)
] @types.builtin


; Attributes
; ----------------------------

(annotation
  name: (identifier) @attributes)

(marker_annotation
  name: (identifier) @attributes)

"@" @attributes


; Variables
; ----------------------------

; -> Normal variables are set at the beginning of the file.


; Values
; ----------------------------

((identifier) @values
 (#match? @values "^_*[A-Z][A-Z\\d_]+$"))

[
  (true)
  (false)
  (null_literal)
] @values.builtin


; Numbers
; ----------------------------

[
  (hex_integer_literal)
  (decimal_integer_literal)
  (octal_integer_literal)
  (decimal_floating_point_literal)
  (hex_floating_point_literal)
] @numbers


; Strings
; ----------------------------

[
  (character_literal)
  (string_literal)
] @strings


; Characters
; ----------------------------

(escape_sequence) @characters


; Comments
; ----------------------------

[
  (line_comment)
  (block_comment)
] @comments
