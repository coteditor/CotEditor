;
;  highlights.scm
;  for LaTeX
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; MARK: Commands
; ----------------------------

; -> Keep before Keywords: `(command_name) @commands` broadly matches all
;    command names, and @keywords patterns must come later to override it.

[
  "{"
  "}"
] @commands

[
  "["
  "]"
] @commands

(command_name) @commands

"\\item" @commands

(text_mode
  command: _ @commands
  content: (curly_group
    (_) @strings))

(caption
  command: _ @commands)

(begin
  command: _ @commands)

(end
  command: _ @commands)

(title_declaration
  command: _ @commands)

(author_declaration
  command: _ @commands)

(chapter
  command: _ @commands)

(part
  command: _ @commands)

(section
  command: _ @commands)

(subsection
  command: _ @commands)

(subsubsection
  command: _ @commands)

(paragraph
  command: _ @commands)

(subparagraph
  command: _ @commands)

(color_set_definition
  command: _ @commands)

(changes_replaced
  command: _ @commands)

[
  (new_command_definition)
  (old_command_definition)
  (let_command_definition)
  (environment_definition)
  (theorem_definition)
] @commands

(paired_delimiter_definition
  declaration: (curly_group_command_name
    (_) @commands))

(class_include
  command: _ @commands
  path: (curly_group_path) @strings)

(latex_include
  command: _ @commands
  path: (curly_group_path) @strings)

(verbatim_include
  command: _ @commands
  path: (curly_group_path) @strings)

(bibstyle_include
  command: _ @commands
  path: (curly_group_path) @strings)

(graphics_include
  command: _ @commands
  path: (curly_group_path) @strings)

(svg_include
  command: _ @commands
  path: (curly_group_path) @strings)

(inkscape_include
  command: _ @commands
  path: (curly_group_path) @strings)

(package_include
  command: _ @commands
  paths: (curly_group_path_list) @strings)

(bibtex_include
  command: _ @commands
  paths: (curly_group_path_list) @strings)

(tikz_library_import
  command: _ @commands
  paths: (curly_group_path_list) @strings)

(import_include
  command: _ @commands
  directory: (curly_group_path) @strings
  file: (curly_group_path) @strings)

(biblatex_include
  "\\addbibresource" @commands
  glob: (curly_group_glob_pattern) @strings)


; MARK: Keywords
; ----------------------------

(generic_command
  (command_name) @keywords
  (#lua-match? @keywords "^\\if[a-zA-Z@]+$"))

(generic_command
  (command_name) @keywords
  (#any-of? @keywords "\\fi" "\\else"))

(delimiter) @keywords


; MARK: Types
; ----------------------------

(title_declaration
  options: (brack_group
    (_) @types)?
  text: (curly_group
    (_) @types))

(chapter
  toc: (brack_group
    (_) @types)?
  text: (curly_group
    (_) @types))

(part
  toc: (brack_group
    (_) @types)?
  text: (curly_group
    (_) @types))

(section
  toc: (brack_group
    (_) @types)?
  text: (curly_group
    (_) @types))

(subsection
  toc: (brack_group
    (_) @types)?
  text: (curly_group
    (_) @types))

(subsubsection
  toc: (brack_group
    (_) @types)?
  text: (curly_group
    (_) @types))

(paragraph
  toc: (brack_group
    (_) @types)?
  text: (curly_group
    (_) @types))

(subparagraph
  toc: (brack_group
    (_) @types)?
  text: (curly_group
    (_) @types))


; MARK: Attributes
; ----------------------------

(generic_command
  arg: (curly_group
    (text
      (word) @attributes)))


; MARK: Variables
; ----------------------------

(placeholder) @variables

(key_value_pair
  key: (_) @variables.parameter
  value: (_) @strings)

(curly_group_spec
  (text) @variables.parameter)

(brack_group_argc) @variables.parameter

(counter_declaration
  command: _ @commands
  counter: (curly_group_word
    (word) @variables)
  supercounter: (brack_group_word
    (word) @variables)?)

(counter_within_declaration
  command: _ @commands
  counter: (curly_group_word
    (word) @variables)
  supercounter: (curly_group_word
    (word) @variables))

(counter_without_declaration
  command: _ @commands
  counter: (curly_group_word
    (word) @variables)
  supercounter: (curly_group_word
    (word) @variables))

(counter_value
  command: _ @commands
  counter: (curly_group_word
    (word) @variables))

(counter_definition
  command: _ @commands
  counter: (curly_group_word
    (word) @variables))

(counter_addition
  command: _ @commands
  counter: (curly_group_word
    (word) @variables))

(counter_increment
  command: _ @commands
  counter: (curly_group_word
    (word) @variables))

(counter_typesetting
  command: _ @commands
  counter: (curly_group_word
    (word) @variables))


; MARK: Values
; ----------------------------

(curly_group_value
  (value_literal) @values)

(begin
  name: (curly_group_text
    (text) @values))

(end
  name: (curly_group_text
    (text) @values))


; MARK: Numbers
; ----------------------------

[
  (displayed_equation)
  (inline_formula)
] @numbers

(math_environment
  (_) @numbers)


; MARK: Strings
; ----------------------------

(label_definition
  command: _ @commands
  name: (curly_group_label
    (_) @strings))

(label_reference_range
  command: _ @commands
  from: (curly_group_label
    (_) @strings)
  to: (curly_group_label
    (_) @strings))

(label_reference
  command: _ @commands
  names: (curly_group_label_list
    (_) @strings))

(label_number
  command: _ @commands
  name: (curly_group_label
    (_) @strings)
  number: (_) @numbers)

(citation
  command: _ @commands
  keys: (curly_group_text_list) @strings)

(hyperlink
  command: _ @commands
  uri: (curly_group_uri
    (_) @strings))

(glossary_entry_definition
  command: _ @commands
  name: (curly_group_text
    (_) @strings))

(glossary_entry_reference
  command: _ @commands
  name: (curly_group_text
    (_) @strings))

(acronym_definition
  command: _ @commands
  name: (curly_group_text
    (_) @strings))

(acronym_reference
  command: _ @commands
  name: (curly_group_text
    (_) @strings))

(color_definition
  command: _ @commands
  name: (curly_group_text
    (_) @strings))

(color_reference
  command: _ @commands
  name: (curly_group_text
    (_) @strings)?)

(begin
  options: (brack_group
    (text
      (word) @strings)))

(new_command_definition
  default: (brack_group
    (_) @strings)?)

(new_command_definition
  implementation: (curly_group
    (_) @strings))

(environment_definition
  begin: (curly_group_impl
    (_) @strings)?)

(environment_definition
  end: (curly_group_impl
    (_) @strings)?)

(paired_delimiter_definition
  body: (curly_group
    (_) @strings)?)

(acronym_definition
  short: (curly_group
    (_) @strings))

(color_set_definition
  ty: (brack_group_text
    (_) @strings)?)

(color_set_definition
  head: (curly_group
    (_) @strings))

(color_set_definition
  spec: (curly_group
    (_) @strings))

(color_set_definition
  tail: (curly_group
    (_) @strings))

(todo
  options: (brack_group
    (_) @strings)?)

(todo
  arg: (curly_group
    (_) @strings))

((generic_environment
  begin: (begin
    name: (curly_group_text
      (text) @_env))
  (curly_group
    (text
      (word) @strings)))
  (#match? @_env "^tabular\\*?$"))


; MARK: Characters
; ----------------------------

[
  (operator)
  "="
  "_"
  "^"
] @characters

(math_delimiter
  left_command: _ @characters
  left_delimiter: _ @characters
  right_command: _ @characters
  right_delimiter: _ @characters)


; MARK: Comments
; ----------------------------

[
  (line_comment)
  (block_comment)
  (comment_environment)
] @comments
