;
;  outline.scm
;  for LaTeX
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; Titles
(title_declaration
  text: (curly_group)) @outline.title

(generic_environment
  begin: (begin
    name: (curly_group_text
      (text) @_env))
  (caption
    long: (curly_group)) @outline.title
  (#not-match? @_env "^sub(figure|table)\\*?$"))

; Headings
(part
  text: (curly_group)) @outline.heading.1

(chapter
  text: (curly_group)) @outline.heading.2

(section
  text: (curly_group)) @outline.heading.3

(subsection
  text: (curly_group)) @outline.heading.4

(subsubsection
  text: (curly_group)) @outline.heading.5

(paragraph
  text: (curly_group)) @outline.heading.6

(subparagraph
  text: (curly_group)) @outline.heading.7

; Conainers
(environment_definition
  name: (curly_group_text)) @outline.container
