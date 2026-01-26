;
; Highlights.scm
; for Python
;
;  CotEditor
;  https://coteditor.com
;
; © 2026 1024jp
;

; set variables at first
; (identifier) @variables


; Keywords
; ----------------------------

[
  "as"
  "assert"
  "async"
  "await"
  "break"
  "class"
  "continue"
  "def"
  "del"
  "elif"
  "else"
  "except"
  "exec"
  "finally"
  "for"
  "from"
  "global"
  "if"
  "import"
  "lambda"
  "nonlocal"
  "pass"
  "print"
  "raise"
  "return"
  "try"
  "while"
  "with"
  "yield"
  "match"
  "case"
] @keywords

[
  "and"
  "in"
  "is"
  "not"
  "or"
  "is not"
  "not in"
] @keywords.operators


; Commands
; ----------------------------

; function calls

(call
  function: (attribute attribute: (identifier) @commands.method))
(call
  function: (identifier) @commands)

; builtin functions

((call
  function: (identifier) @commands.builtin)
 (#match?
   @commands.builtin
   "^(abs|all|any|ascii|bin|bool|breakpoint|bytearray|bytes|callable|chr|classmethod|compile|complex|delattr|dict|dir|divmod|enumerate|eval|exec|filter|float|format|frozenset|getattr|globals|hasattr|hash|help|hex|id|input|int|isinstance|issubclass|iter|len|list|locals|map|max|memoryview|min|next|object|oct|open|ord|pow|print|property|range|repr|reversed|round|set|setattr|slice|sorted|staticmethod|str|sum|super|tuple|type|vars|zip|__import__)$"))

; function definitions

(function_definition
  name: (identifier) @commands)


; Types
; ----------------------------

(type (identifier) @types)

((identifier) @types.constant
 (#match? @types.constant "^[A-Z][A-Z_]*$"))

((identifier) @types.constructor
 (#match? @types.constructor "^[A-Z]"))


; Attributes
; ----------------------------

; decorators

; @name
(decorator
  "@" @attributes
  (identifier) @attributes)

; @pkg.name
(decorator
  "@" @attributes
  (attribute attribute: (identifier) @attributes))

; @name(...)
(decorator
  "@" @attributes
  (call
    function: (identifier) @attributes))

; @pkg.name(...)
(decorator
  "@" @attributes
  (call
    function: (attribute attribute: (identifier) @attributes)))


; Variables
; ----------------------------

; Normal variables are set at the beginning of the file.

; self/super
((identifier) @variables
  (#eq? @variables "self"))
((identifier) @variables
  (#eq? @variables "super"))


; Values
; ----------------------------

[
  (none)
  (true)
  (false)
] @values.builtin

; dunder identifiers: __name__, __future__, __annotations__, etc.
((identifier) @values
  (#match? @values "^__\\w+__$"))
(future_import_statement
  "__future__" @values)


; Numbers
; ----------------------------

[
  (integer)
  (float)
] @numbers


; Strings
; ----------------------------

(string) @strings


; Characters
; ----------------------------

(escape_sequence) @characters


; Comments
; ----------------------------

(comment) @comments
