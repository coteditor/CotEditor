;
;  outline.scm
;  for HTML
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; Titles
((element
   (start_tag (tag_name) @tag)
   (text) @outline.title)
  (#eq? @tag "title"))

((element
   (start_tag (tag_name) @tag)
   (text) @outline.title)
  (#eq? @tag "figcaption"))

((element
   (start_tag (tag_name) @tag)
   (text) @outline.title)
  (#eq? @tag "caption"))

; Headings
((element
   (start_tag (tag_name) @tag)
   (text) @outline.heading.1)
  (#eq? @tag "h1"))

((element
   (start_tag (tag_name) @tag)
   (text) @outline.heading.2)
  (#eq? @tag "h2"))

((element
   (start_tag (tag_name) @tag)
   (text) @outline.heading.3)
  (#eq? @tag "h3"))

((element
   (start_tag (tag_name) @tag)
   (text) @outline.heading.4)
  (#eq? @tag "h4"))

((element
   (start_tag (tag_name) @tag)
   (text) @outline.heading.5)
  (#eq? @tag "h5"))

((element
   (start_tag (tag_name) @tag)
   (text) @outline.heading.6)
  (#eq? @tag "h6"))

; Separators
((self_closing_tag (tag_name) @outline.separator)
  (#eq? @outline.separator "hr"))

((element
   (start_tag (tag_name) @outline.separator))
  (#eq? @outline.separator "hr"))
