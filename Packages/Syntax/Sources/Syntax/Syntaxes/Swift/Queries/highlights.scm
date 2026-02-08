;
; Highlights.scm
; for Swift
;
;  CotEditor
;  https://coteditor.com
;
; © 2026 1024jp
;

; MARK: Keywords
; ----------------------------

[
  "protocol"
  "extension"
  "indirect"
  "nonisolated"
  "override"
  "convenience"
  "required"
  "some"
  "any"
  "weak"
  "unowned"
  "didSet"
  "willSet"
  "subscript"
  "let"
  "var"
  (throws)
  (where_keyword)
  (getter_specifier)
  (setter_specifier)
  (modify_specifier)
  (else)
  (as_operator)
] @keywords

(if_statement
  "if" @keywords)

[
  "enum"
  "struct"
  "class"
  "typealias"
] @keywords

[
  "async"
  "await"
] @keywords

(import_declaration
  "import" @keywords)

(enum_entry
  "case" @keywords)

; statements
(for_statement
  "for" @keywords)
(for_statement
  "in" @keywords)
(lambda_literal
  "in" @keywords)

[
  "while"
  "repeat"
  "continue"
  "break"
] @keywords

(guard_statement
  "guard" @keywords)

(switch_statement
  "switch" @keywords)
(switch_entry
  "case" @keywords)
(switch_entry
  "fallthrough" @keywords)
(switch_entry
  (default_keyword) @keywords)

(init_declaration
  "init" @keywords)
[
  "func"
  "deinit"
  "return"
] @keywords

[
  (try_operator)
  "do"
  (throw_keyword)
  (catch_keyword)
] @keywords

; modifiers (public/private, mutating, override, weak…)
[
  (visibility_modifier)
  (member_modifier)
  (function_modifier)
  (property_modifier)
  (parameter_modifier)
  (inheritance_modifier)
  (mutation_modifier)
] @keywords

(shebang_line) @keywords

; self/super
[
  (self_expression)
  (super_expression)
] @keywords


; MARK: Types
; ----------------------------

(type_identifier) @types

; Self
(user_type (type_identifier) @types
  (#eq? @types "Self")
)

; SomeType.method(): highlight SomeType as a type
((navigation_expression
  (simple_identifier) @types)
  (#match? @types "^[A-Z]"))


; Attributes
; ----------------------------

(modifiers
  (attribute
    "@" @attributes
    (user_type (type_identifier) @attributes)
  )
)

[
  (diagnostic)
  (availability_condition)
  (playground_literal)
  (key_path_string_expression)
  (selector_expression)
  (external_macro_definition)
] @attributes


; MARK: Variables
; ----------------------------

; parameter names
(parameter external_name: (simple_identifier) @variables)
(parameter name: (simple_identifier) @variables)

(type_parameter
  (type_identifier) @variables)

(inheritance_constraint
  (identifier
    (simple_identifier) @variables))

(equality_constraint
  (identifier
    (simple_identifier) @variables))


; property declarations
(class_body
  (property_declaration
    (pattern (simple_identifier) @variables)
  )
)
(protocol_property_declaration
  (pattern
    (simple_identifier) @variables))

(navigation_expression
  (navigation_suffix
    (simple_identifier) @variables))


; MARK: Commands
; ----------------------------

; function declarations
(function_declaration
  (simple_identifier) @commands)

(protocol_function_declaration
  name: (simple_identifier) @commands)

; foo()
(call_expression
  (simple_identifier) @commands
)

; foo.bar.baz(): highlight the baz()
(call_expression
  (navigation_expression
    (navigation_suffix (simple_identifier) @commands)
  )
)

; .foo()
(call_expression
  (prefix_expression (simple_identifier) @commands)
)


; MARK: Values
; ----------------------------

(boolean_literal) @values
"nil" @values


; MARK: Numbers
; ----------------------------

[
  (integer_literal)
  (hex_literal)
  (oct_literal)
  (bin_literal)
  (real_literal)
] @numbers


; MARK: Strings
; ----------------------------

[
  (line_str_text)
  (multi_line_str_text)
  (raw_str_part)
  (raw_str_end_part)
] @strings

(regex_literal) @strings

; string interpolations
(line_string_literal [ "\\(" ")" ]) @keywords
(multi_line_string_literal [ "\\(" ")" ]) @keywords
(raw_str_interpolation [ (raw_str_interpolation_start) ")" ]) @keywords

; string delimiters
[
  "\""
  "\"\"\""
] @strings


; MARK: Characters
; ----------------------------

; escaped characters (\n, \t, \u{...}, etc.)
(str_escaped_char) @characters

(wildcard_pattern) @characters


; MARK: Comments
; ----------------------------

[
  (comment)
  (multiline_comment)
] @comments
