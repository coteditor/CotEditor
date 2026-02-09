;
; Highlights.scm
; for Ruby
;
;  CotEditor
;  https://coteditor.com
;
; © 2026 1024jp
;

; set variables at first
; (identifier) @variables


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
  "defined?"
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

; function calls
(call
  method: [(identifier) (constant)] @commands.method)
(call method: (identifier) @commands.method
  (#any-of? @commands.method "require"))

; function definitions
(alias (identifier) @commands.method)
(setter (identifier) @commands.method)
(method name: [(identifier) (constant)] @commands.method)
(singleton_method name: [(identifier) (constant)] @commands.method)


; MARK: Types
; ----------------------------

(constant) @types


; MARK: Attributes
; ----------------------------

[
  (class_variable)
  (instance_variable)
] @attributes



; MARK: Variables
; ----------------------------

(global_variable) @variables

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

; special symbols
[
  (simple_symbol)
  (delimited_symbol)
  (hash_key_symbol)
  (bare_symbol)
] @strings

(regex) @strings


; MARK: Characters
; ----------------------------

(escape_sequence) @characters

(interpolation
  "#{" @characters.special
  "}" @characters.special) @embedded


; MARK: Comments
; ----------------------------

(comment) @comments
