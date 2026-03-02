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
  (atx_h1_marker)) @outline.heading.1)

((atx_heading
  (atx_h2_marker)) @outline.heading.2)

((atx_heading
  (atx_h3_marker)) @outline.heading.3)

((atx_heading
  (atx_h4_marker)) @outline.heading.4)

((atx_heading
  (atx_h5_marker)) @outline.heading.5)

((atx_heading
  (atx_h6_marker)) @outline.heading.6)

; headings with underline (setext)
((setext_heading
  (setext_h1_underline)) @outline.heading.1)

((setext_heading
  (setext_h2_underline)) @outline.heading.2)

; separators
(thematic_break) @outline.separator
