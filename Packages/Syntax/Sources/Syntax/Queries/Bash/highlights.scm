;
;  Highlights.scm
;  for Bash
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; Keywords
; ----------------------------

[
  "case"
  "do"
  "done"
  "elif"
  "else"
  "esac"
  "export"
  "fi"
  "for"
  "function"
  "if"
  "in"
  "select"
  "then"
  "unset"
  "until"
  "while"
] @keywords


; Commands
; ----------------------------

((command_name) @commands
 (#not-match? @commands "^[A-Z_][A-Z0-9_]*$"))

(function_definition
  name: (word) @commands)


; Variables
; ----------------------------

(variable_name) @variables


; Values
; ----------------------------

((command
  (_) @values)
 (#match? @values "^-"))


; Numbers
; ----------------------------

(file_descriptor) @numbers


; Strings
; ----------------------------

[
  (string)
  (raw_string)
  (heredoc_body)
  (heredoc_start)
] @strings


; Characters
; ----------------------------

[
  (command_substitution)
  (process_substitution)
  (expansion)
  "$"
  "&&"
  ">"
  ">>"
  "<"
  "|"
] @characters


; Comments
; ----------------------------

(comment) @comments
