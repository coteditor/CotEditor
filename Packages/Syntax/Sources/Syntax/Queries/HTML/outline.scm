;
;  outline.scm
;  for HTML
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; headings (title + h1-h6)
((element
   (start_tag (tag_name) @tag)
   (text) @outline.heading.1)
  (#match? @tag "^h1$"))

((element
   (start_tag (tag_name) @tag)
   (text) @outline.heading.2)
  (#match? @tag "^h2$"))

((element
   (start_tag (tag_name) @tag)
   (text) @outline.heading.3)
  (#match? @tag "^h3$"))

((element
   (start_tag (tag_name) @tag)
   (text) @outline.heading.4)
  (#match? @tag "^h4$"))

((element
   (start_tag (tag_name) @tag)
   (text) @outline.heading.5)
  (#match? @tag "^h5$"))

((element
   (start_tag (tag_name) @tag)
   (text) @outline.heading.6)
  (#match? @tag "^h6$"))

((element
   (start_tag (tag_name) @tag)
   (text) @outline.heading.title)
  (#match? @tag "^title$"))

; hr separator
((self_closing_tag (tag_name) @outline.separator)
  (#match? @outline.separator "^hr$"))

((element
   (start_tag (tag_name) @outline.separator))
  (#match? @outline.separator "^hr$"))
