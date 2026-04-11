;
;  highlights.scm
;  for CSS
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; MARK: Keywords
; ----------------------------

[
  (namespace_name)
  (property_name)
  (feature_name)
] @keywords

; operators in media queries
[
  "and"
  "or"
  "not"
  "only"
] @keywords


; MARK: Commands
; ----------------------------

(function_name) @commands

[
  "@import"
  "@charset"
  "@keyframes"
  "@media"
  "@namespace"
  "@scope"
  "@supports"
  (at_keyword)
  (to)
  (from)
] @commands


; MARK: Types
; ----------------------------

(important) @types


; MARK: Attributes
; ----------------------------

; selectors
[
  (tag_name)
  (nesting_selector)
  (universal_selector)
] @attributes

; pseudo-elements (::before, ::after)
(pseudo_element_selector (tag_name) @attributes)

; pseudo-classes (:hover, :focus)
(pseudo_class_selector (class_name) @attributes)

(attribute_name) @attributes


; MARK: Values
; ----------------------------

(plain_value) @values


; MARK: Variables
; ----------------------------

[
  (class_name)
  (id_name)
] @variables

((property_name) @variables
 (#match? @variables "^--"))
((plain_value) @variables
 (#match? @variables "^--"))


; MARK: Numbers
; ----------------------------

[
  (integer_value)
  (float_value)
] @numbers

(unit) @numbers

; for like `16px/1.5`
((plain_value) @numbers
 (#match? @numbers "^(%|px|em|rem|ex|rex|ch|rch|ic|ric|cap|rcap|lh|rlh|cm|mm|Q|q|in|pt|pc)/[0-9]*\.?[0-9]+$"))


; MARK: Strings
; ----------------------------

(attribute_selector (plain_value) @strings)

(string_value) @strings
(color_value) @strings


; MARK: Comments
; ----------------------------

(comment) @comments
