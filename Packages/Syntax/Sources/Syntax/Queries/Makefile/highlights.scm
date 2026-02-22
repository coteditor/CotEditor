;
; Highlights.scm
; for Makefile
;
;  CotEditor
;  https://coteditor.com
;
; © 2026 1024jp
;

; Keywords
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


; Commands
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


; Types
; ----------------------------

(targets
  (word) @types)

((word) @types
  (#match? @types "[\\%\\*\\?]"))


; Variables
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


; Strings
; ----------------------------

[
  (text)
  (string)
] @strings


; Comments
; ----------------------------

(comment) @comments
