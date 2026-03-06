;
;  highlights.scm
;  for C#
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; MARK: Keywords
; ----------------------------

[
  (modifier)
  "this"
  (implicit_type)
] @keywords

[
  "add"
  "alias"
  "as"
  "base"
  "break"
  "case"
  "catch"
  "checked"
  "class"
  "continue"
  "default"
  "delegate"
  "do"
  "else"
  "enum"
  "event"
  "explicit"
  "extern"
  "finally"
  "for"
  "foreach"
  "global"
  "goto"
  "if"
  "implicit"
  "interface"
  "is"
  "lock"
  "namespace"
  "notnull"
  "operator"
  "params"
  "return"
  "remove"
  "sizeof"
  "stackalloc"
  "static"
  "struct"
  "switch"
  "throw"
  "try"
  "typeof"
  "unchecked"
  "using"
  "while"
  "new"
  "await"
  "in"
  "yield"
  "get"
  "set"
  "when"
  "out"
  "ref"
  "from"
  "where"
  "select"
  "record"
  "init"
  "with"
  "let"
] @keywords


; MARK: Commands
; ----------------------------

(method_declaration name: (identifier) @commands.method)
(local_function_statement name: (identifier) @commands.method)
(constructor_declaration name: (identifier) @commands.method)
(destructor_declaration name: (identifier) @commands.method)
(invocation_expression function: (identifier) @commands.method)
(invocation_expression (member_access_expression name: (identifier) @commands.method))


; MARK: Types
; ----------------------------

(interface_declaration name: (identifier) @types)
(class_declaration name: (identifier) @types)
(enum_declaration name: (identifier) @types)
(struct_declaration (identifier) @types)
(record_declaration (identifier) @types)
(namespace_declaration name: (_) @types)
(generic_name (identifier) @types)
(type_argument_list (identifier) @types)
(as_expression right: (identifier) @types)
(is_expression right: (identifier) @types)
(base_list (identifier) @types)
(predefined_type) @types.builtin


; MARK: Attributes
; ----------------------------

(attribute name: (identifier) @attributes)
(type_parameter (identifier) @attributes)


; MARK: Variables
; ----------------------------

(parameter name: (identifier) @variables)
(variable_declarator name: (identifier) @variables)
(declaration_expression name: (identifier) @variables)
(declaration_pattern name: (identifier) @variables)
(catch_declaration name: (identifier) @variables)
(from_clause name: (identifier) @variables)
(foreach_statement left: (identifier) @variables)


; MARK: Values
; ----------------------------

(enum_member_declaration (identifier) @values)

[
  (boolean_literal)
  (null_literal)
] @values.builtin


; MARK: Numbers
; ----------------------------

[
  (real_literal)
  (integer_literal)
] @numbers


; MARK: Strings
; ----------------------------

[
  (character_literal)
  (string_literal)
  (raw_string_literal)
  (verbatim_string_literal)
  (interpolated_string_expression)
] @strings


; MARK: Characters
; ----------------------------

(escape_sequence) @characters


; MARK: Comments
; ----------------------------

(comment) @comments
