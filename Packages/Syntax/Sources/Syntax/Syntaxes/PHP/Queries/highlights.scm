;
; Highlights.scm
; for PHP
;
;  CotEditor
;  https://coteditor.com
;
; © 2026 1024jp
;

; Keywords
; ----------------------------

[
  "and"
  "as"
  "break"
  "case"
  "catch"
  "class"
  "clone"
  "const"
  "continue"
  "declare"
  "default"
  "do"
  "echo"
  "else"
  "elseif"
  "enddeclare"
  "endfor"
  "endforeach"
  "endif"
  "endswitch"
  "endwhile"
  "enum"
  "exit"
  "extends"
  "finally"
  "fn"
  "for"
  "foreach"
  "function"
  "global"
  "goto"
  "if"
  "implements"
  "include"
  "include_once"
  "instanceof"
  "insteadof"
  "interface"
  "match"
  "namespace"
  "new"
  "or"
  "print"
  "require"
  "require_once"
  "return"
  "switch"
  "throw"
  "trait"
  "try"
  "use"
  "while"
  "xor"
  "yield"
  "yield from"
  (abstract_modifier)
  (final_modifier)
  (readonly_modifier)
  (static_modifier)
  (visibility_modifier)
] @keywords

(function_static_declaration "static" @keywords)

[
  (php_tag)
  (php_end_tag)
] @keywords.tag


; Commands
; ----------------------------

(namespace_use_clause
  type: "function"
  [
    (name) @commands
    (qualified_name
      (name) @commands)
    alias: (name) @commands
  ])

(array_creation_expression "array" @commands.builtin)
(list_literal "list" @commands.builtin)
(exit_statement "exit" @commands.builtin "(")

(method_declaration
  name: (name) @commands.method)

(function_call_expression
  function: [
    (qualified_name (name))
    (relative_name (name))
    (name)
  ] @commands)

(scoped_call_expression
  name: (name) @commands)

(member_call_expression
  name: (name) @commands.method)

(nullsafe_member_call_expression
  name: (name) @commands.method)

(function_definition
  name: (name) @commands)


; Types
; ----------------------------

(namespace_definition
  name: (namespace_name
    (name) @types))

(namespace_name
  (name) @types)
  
(relative_name "namespace" @types.builtin)

(namespace_use_clause
  !type
  [
    (name) @types
    (qualified_name
      (name) @types)
    alias: (name) @types
  ])

(primitive_type) @types.builtin
(cast_type) @types.builtin
(named_type [
  (name) @types
  (qualified_name (name) @types)
  (relative_name (name) @types)
]) @types
(named_type (name) @types.builtin
  (#any-of? @types.builtin "static" "self" "parent"))

(object_creation_expression [
  (name) @types
  (qualified_name (name) @types)
  (relative_name (name) @types)
])

(base_clause
  [
    (name) @types
    (qualified_name (name) @types)
    (relative_name (name) @types)
  ])

(class_interface_clause
  [
    (name) @types
    (qualified_name (name) @types)
    (relative_name (name) @types)
  ])

(class_declaration
  name: (name) @types)
(interface_declaration
  name: (name) @types)
(trait_declaration
  name: (name) @types)
(enum_declaration
  name: (name) @types)

(scoped_call_expression
  scope: [
    (name) @types
    (qualified_name (name) @types)
    (relative_name (name) @types)
  ])

(class_constant_access_expression
  [
    (name) @types
    (qualified_name (name) @types)
    (relative_name (name) @types)
  ])


; Attributes
; ----------------------------

(attribute_group
  "#[" @attributes
  "]" @attributes)

(attribute [
  (name) @attributes
  (qualified_name
    (name) @attributes)
  (relative_name
    (name) @attributes)
])

(attribute
  parameters: (arguments
    (argument
      name: (name) @attributes)))


; Variables
; ----------------------------

; property
(property_element
  (variable_name) @variables)
[
  (member_access_expression
    name: (variable_name (name)) @variables)
  (nullsafe_member_access_expression
    name: (variable_name (name)) @variables)
  (scoped_property_access_expression
    name: (variable_name (name)) @variables)
]
[
  (member_access_expression
    name: (name) @variables)
  (nullsafe_member_access_expression
    name: (name) @variables)
]

(relative_scope) @variables
(variable_name) @variables
((name) @variables
 (#eq? @variables "this"))

; class constants
(class_declaration
  body: (declaration_list
    (const_declaration
      (const_element
        (name) @variables))))


; Values
; ----------------------------

(namespace_use_clause
  type: "const"
  [
    (name) @values
    (qualified_name
      (name) @values)
    alias: (name) @values
  ])

; magic constants
((name) @values
 (#any-of? @values
  "__LINE__"
  "__FILE__"
  "__DIR__"
  "__FUNCTION__"
  "__CLASS__"
  "__TRAIT__"
  "__METHOD__"
  "__NAMESPACE__"
  "__COMPILER_HALT_OFFSET__"
))

; error reporting levels
((name) @values
 (#any-of? @values
  "E_ERROR"
  "E_WARNING"
  "E_PARSE"
  "E_NOTICE"
  "E_CORE_ERROR"
  "E_CORE_WARNING"
  "E_COMPILE_ERROR"
  "E_COMPILE_WARNING"
  "E_USER_ERROR"
  "E_USER_WARNING"
  "E_USER_NOTICE"
  "E_STRICT"
  "E_RECOVERABLE_ERROR"
  "E_DEPRECATED"
  "E_USER_DEPRECATED"
  "E_ALL"
))

(const_declaration (const_element (name) @values))

[
  (boolean)
  (null)
] @values


; Numbers
; ----------------------------

[
  (integer)
  (float)
] @numbers


; Strings
; ----------------------------

[
  (string)
  (string_content)
  (encapsed_string)
  (heredoc)
  (heredoc_body)
  (nowdoc_body)
] @strings


; Characters
; ----------------------------


; Comments
; ----------------------------

(comment) @comments
