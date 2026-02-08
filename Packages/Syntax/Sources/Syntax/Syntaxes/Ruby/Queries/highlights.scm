;
; Highlights.scm
; for Ruby
;
;  CotEditor
;  https://coteditor.com
;
; © 2026 1024jp
;

(identifier) @variables


; MARK: Keywords
; ----------------------------

[
  "alias"
  "and"
  "begin"
  "break"
  "case"
  "class"
  "def"
  "do"
  "else"
  "elsif"
  "end"
  "ensure"
  "for"
  "if"
  "in"
  "module"
  "next"
  "or"
  "rescue"
  "retry"
  "return"
  "then"
  "unless"
  "until"
  "when"
  "while"
  "yield"
] @keywords

((identifier) @keywords
 (#match? @keywords "^(private|protected|public)$"))


; MARK: Commands
; ----------------------------

((identifier) @commands.method
 (#is-not? local))

; Function calls

"defined?" @commands.method.builtin

(call
  method: [(identifier) (constant)] @commands.method)

((identifier) @commands.method.builtin
 (#eq? @commands.method.builtin "require"))

; Function definitions

(alias (identifier) @commands.method)
(setter (identifier) @commands.method)
(method name: [(identifier) (constant)] @commands.method)
(singleton_method name: [(identifier) (constant)] @commands.method)


; MARK: Types
; ----------------------------

(constant) @types.constructor


; MARK: Attributes
; ----------------------------

; Identifiers

[
  (class_variable)
  (instance_variable)
] @attributes



; MARK: Variables
; ----------------------------

[
  (self)
  (super)
] @variables.builtin

(block_parameter (identifier) @variables.parameter)
(block_parameters (identifier) @variables.parameter)
(destructured_parameter (identifier) @variables.parameter)
(hash_splat_parameter (identifier) @variables.parameter)
(lambda_parameters (identifier) @variables.parameter)
(method_parameters (identifier) @variables.parameter)
(splat_parameter (identifier) @variables.parameter)

(keyword_parameter name: (identifier) @variables.parameter)
(optional_parameter name: (identifier) @variables.parameter)


; MARK: Values
; ----------------------------

[
  (nil)
  (true)
  (false)
] @values.builtin

((identifier) @values.builtin
 (#match? @values.builtin "^__(FILE|LINE|ENCODING)__$"))

[
  (file)
  (line)
  (encoding)
] @values.builtin

((constant) @values
 (#match? @values "^[A-Z\\d_]+$"))


; MARK: Numbers
; ----------------------------

[
  (integer)
  (float)
] @numbers


; MARK: Strings
; ----------------------------

[
  (string)
  (bare_string)
  (subshell)
  (heredoc_body)
  (heredoc_beginning)
] @strings

[
  (simple_symbol)
  (delimited_symbol)
  (hash_key_symbol)
  (bare_symbol)
] @strings.special.symbol

(regex) @strings.special.regex


; MARK: Characters
; ----------------------------

(escape_sequence) @characters

(interpolation
  "#{" @characters.special
  "}" @characters.special) @embedded


; MARK: Comments
; ----------------------------

(comment) @comments
