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
  "enum"
  "struct"
  "class"
  "typealias"
  "async"
  "await"
  (throws)
  (where_keyword)
  (getter_specifier)
  (setter_specifier)
  (modify_specifier)
  (else)
  (as_operator)
  
  "while"
  "repeat"
  "continue"
  "break"
  
  "func"
  "deinit"
  "return"
  
  (try_operator)
  "do"
  (throw_keyword)
  (catch_keyword)
] @keywords

; statements
(if_statement
  "if" @keywords)
(guard_statement
  "guard" @keywords)

(import_declaration
  "import" @keywords)

(enum_entry
  "case" @keywords)

(for_statement
  "for" @keywords)
(for_statement
  "in" @keywords)
(lambda_literal
  "in" @keywords)

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

; self/super
[
  (self_expression)
  (super_expression)
] @keywords

(shebang_line) @keywords


; MARK: Commands
; ----------------------------

; function declarations
(function_declaration
  (simple_identifier) @commands)

(protocol_function_declaration
  name: (simple_identifier) @commands)

; foo(...): only () calls are commands
(call_expression
  (simple_identifier) @commands
  (call_suffix
    (value_arguments
      "(" (_)? ")" )))

; foo.bar.baz(): highlight baz only when it's a () call
(call_expression
  (navigation_expression
    (navigation_suffix (simple_identifier) @commands))
  (call_suffix
    (value_arguments
      "(" (_)? ")" )))

; .foo()
(call_expression
  (prefix_expression (simple_identifier) @commands)
)

; #macro(...)
(macro_invocation
  "#" @commands
  (simple_identifier) @commands)


; MARK: Types
; ----------------------------

(type_identifier) @types

; Type-like member access in expressions: Foo.shared...
(navigation_expression
  target: (simple_identifier) @types
  (#match? @types "^[A-Z]"))

; Type-like initializer calls: String(...), URL(...), Foo(...)
(call_expression
  (simple_identifier) @types
  (#match? @types "^[A-Z]"))
  
; Self
(user_type (type_identifier) @types
  (#eq? @types "Self")
)


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

; closure shorthand arguments: $0, $1, ...
((simple_identifier) @variables
  (#match? @variables "^\\$[0-9]+$"))


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
  (raw_str_continuing_indicator)
  (raw_str_end_part)
] @strings

(regex_literal) @strings

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

; delimiters for string interpolation
(line_string_literal [ "\\(" ")" ] @characters)
(multi_line_string_literal [ "\\(" ")" ] @characters)
(raw_str_interpolation [ (raw_str_interpolation_start) ")" ] @characters)


; MARK: Comments
; ----------------------------

[
  (comment)
  (multiline_comment)
] @comments
