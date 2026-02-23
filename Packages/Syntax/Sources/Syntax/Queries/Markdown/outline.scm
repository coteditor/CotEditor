;
;  outline.scm
;  for Markdown
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

((atx_heading
  (atx_h1_marker)) @outline.heading.h1)

((atx_heading
  (atx_h2_marker)) @outline.heading.h2)

((atx_heading
  (atx_h3_marker)) @outline.heading.h3)

((atx_heading
  (atx_h4_marker)) @outline.heading.h4)

((atx_heading
  (atx_h5_marker)) @outline.heading.h5)

((atx_heading
  (atx_h6_marker)) @outline.heading.h6)

; headings with underline (setext)
((setext_heading
  (setext_h1_underline)) @outline.heading.h1)

((setext_heading
  (setext_h2_underline)) @outline.heading.h2)

; separators
(thematic_break) @outline.separator
