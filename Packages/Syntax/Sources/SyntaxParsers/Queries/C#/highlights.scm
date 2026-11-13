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
  "goto"
  "if"
  "implicit"
  "interface"
  "is"
  "lock"
  "namespace"
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
  "get"
  "set"
  "out"
  "ref"
  "record"
  "init"
  "with"
] @keywords

; query expressions
(from_clause "from" @keywords)
(let_clause "let" @keywords)
(where_clause "where" @keywords)
(select_clause "select" @keywords)
(order_by_clause ["orderby" "ascending" "descending"] @keywords)
(group_clause ["group" "by"] @keywords)
(join_clause ["join" "on" "equals"] @keywords)
(join_into_clause "into" @keywords)
(query_expression "into" @keywords)

; pattern combinators
(and_pattern "and" @keywords)
(or_pattern "or" @keywords)
(negated_pattern "not" @keywords)

; contextual keywords
; -> Match them only in their nodes, as identifiers with the same names contain the keyword tokens.
(extern_alias_directive "alias" @keywords)
(using_directive "global" @keywords)
((alias_qualified_name
  alias: (identifier) @keywords)
 (#eq? @keywords "global"))
(type_parameter_constraints_clause "where" @keywords)
(type_parameter_constraint ["notnull" "unmanaged"] @keywords)
(yield_statement "yield" @keywords)
(when_clause "when" @keywords)
(catch_filter_clause "when" @keywords)
(calling_convention ["managed" "unmanaged"] @keywords)

(fixed_statement "fixed" @keywords)
(unsafe_statement "unsafe" @keywords)
(ref_type "readonly" @keywords)


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

; ALL_CAPS names (commands, types, and attributes below override)
((identifier) @values
  (#match? @values "^[A-Z][A-Z\\d_]*$"))

(enum_member_declaration (identifier) @values)

[
  (boolean_literal)
  (null_literal)
] @values.builtin


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
(is_pattern_expression pattern: (constant_pattern (identifier) @types))
(base_list (identifier) @types)
(predefined_type) @types.builtin

; type positions (variables, parameters, returns, `new`, casts, patterns)
(_ type: (identifier) @types)
(_ returns: (identifier) @types)


; MARK: Attributes
; ----------------------------

(attribute name: (identifier) @attributes)
(type_parameter (identifier) @attributes)


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
