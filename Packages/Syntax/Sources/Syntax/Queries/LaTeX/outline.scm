;
;  outline.scm
;  for LaTeX
;
;  CotEditor
;  https://coteditor.com
;

(title_declaration
  text: (curly_group
    (_) @outline.heading.1))

(part
  text: (curly_group
    (_) @outline.heading.1))

(chapter
  text: (curly_group
    (_) @outline.heading.2))

(section
  text: (curly_group
    (_) @outline.heading.3))

(subsection
  text: (curly_group
    (_) @outline.heading.4))

(subsubsection
  text: (curly_group
    (_) @outline.heading.5))

(paragraph
  text: (curly_group
    (_) @outline.heading.6))

(subparagraph
  text: (curly_group
    (_) @outline.heading.7))

(environment_definition
  name: (curly_group_text
    (_) @outline.container))
