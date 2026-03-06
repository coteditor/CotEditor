;
;  highlights.scm
;  for Makefile
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; MARK: Keywords
; ----------------------------

[
  "ifeq"
  "ifneq"
  "ifdef"
  "ifndef"
  "else"
  "endif"
  "if"
  "or"
  "and"
  "foreach"
  "define"
  "endef"
  "vpath"
  "undefine"
  "export"
  "unexport"
  "override"
  "private"
  "include"
  "sinclude"
  "-include"
] @keywords


; MARK: Commands
; ----------------------------

[
  "subst"
  "patsubst"
  "strip"
  "findstring"
  "filter"
  "filter-out"
  "sort"
  "word"
  "words"
  "wordlist"
  "firstword"
  "lastword"
  "dir"
  "notdir"
  "suffix"
  "basename"
  "addsuffix"
  "addprefix"
  "join"
  "wildcard"
  "realpath"
  "abspath"
  "call"
  "eval"
  "file"
  "value"
  "shell"
  "error"
  "warning"
  "info"
] @commands


; MARK: Types
; ----------------------------

(targets
  (word) @types)

((word) @types
  (#match? @types "[\\%\\*\\?]"))


; MARK: Variables
; ----------------------------

(variable_assignment
  name: (word) @variables)

(variable_reference
  (word) @variables)

(automatic_variable
 [ "@" "%" "<" "?" "^" "+" "/" "*" "D" "F"] @variables)

[
  "VPATH"
  ".RECIPEPREFIX"
] @variables


; MARK: Strings
; ----------------------------

[
  (text)
  (string)
] @strings


; MARK: Comments
; ----------------------------

(comment) @comments
