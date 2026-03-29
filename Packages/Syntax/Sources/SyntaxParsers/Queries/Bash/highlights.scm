;
;  highlights.scm
;  for Bash
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; MARK: Keywords
; ----------------------------

[
  "case"
  "declare"
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
  "local"
  "readonly"
  "select"
  "then"
  "typeset"
  "unset"
  "until"
  "while"
] @keywords


; MARK: Commands
; ----------------------------

((command_name) @commands
 (#not-match? @commands "^[A-Z_][A-Z0-9_]*$"))

(function_definition
  name: (word) @commands)


; MARK: Variables
; ----------------------------

(variable_name) @variables


; MARK: Values
; ----------------------------

((command
  (_) @values)
 (#match? @values "^-"))


; MARK: Numbers
; ----------------------------

(file_descriptor) @numbers


; MARK: Strings
; ----------------------------

[
  (string)
  (raw_string)
  (heredoc_body)
  (heredoc_start)
] @strings


; MARK: Characters
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


; MARK: Comments
; ----------------------------

(comment) @comments
