;
;  highlights.scm
;  for Python
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; set variables at first
; (identifier) @variables


; MARK: Keywords
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
] @keywords


; MARK: Commands
; ----------------------------

; general attribute access: obj.attr / pkg.mod.name
; Attributes: intentionally placed *before* @commands.
(attribute
  attribute: (identifier) @attributes)
  
  
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

; call of dunder methods
(call
  function: (identifier) @commands
  (#match? @commands "^__\\w+__$"))


; MARK: Types
; ----------------------------

; Prefer UPPER_SNAKE_CASE / ALL_CAPS as values by default.
; More specific type contexts below override this via "last pattern wins".
((identifier) @values
 (#match? @values "^[A-Z][A-Z0-9_]*$"))

(class_definition
  name: (identifier) @types)

(type (identifier) @types)

((identifier) @types.constructor
 (#match? @types.constructor "^[A-Z].*[a-z]"))

((call
  function: (identifier) @types.constructor)
 (#match? @types.constructor "^[A-Z][A-Z0-9_]*$"))

((call
  function: (attribute attribute: (identifier) @types.constructor))
 (#match? @types.constructor "^[A-Z][A-Z0-9_]*$"))


; MARK: Attributes (decorators)
; ----------------------------

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


; MARK: Variables
; ----------------------------

; Normal variables are set at the beginning of the file.

; self/super
((identifier) @variables
  (#eq? @variables "self"))
((identifier) @variables
  (#eq? @variables "super"))


; MARK: Values
; ----------------------------

[
  (none)
  (true)
  (false)
] @values.builtin

; dunder constants / meta identifiers
((identifier) @values
  (#any-of? @values
    "__name__"
    "__main__"
    "__file__"
    "__package__"
    "__spec__"
    "__doc__"
    "__all__"
    "__annotations__"
    "__debug__"
    "__author__"
    "__copyright__"))
(future_import_statement
  "__future__" @values)


; MARK: Numbers
; ----------------------------

[
  (integer)
  (float)
] @numbers


; MARK: Strings
; ----------------------------

(string) @strings


; MARK: Characters
; ----------------------------

(escape_sequence) @characters


; MARK: Comments
; ----------------------------

(comment) @comments
