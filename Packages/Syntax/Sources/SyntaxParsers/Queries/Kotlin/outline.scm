;
;  outline.scm
;  for Kotlin
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; Containers
(class_declaration
  (type_identifier) @outline.container)

(object_declaration
  (type_identifier) @outline.container)

(companion_object
  (type_identifier) @outline.container)

; Functions
(function_declaration
  (simple_identifier) @outline.function
  (function_value_parameters) @outline.signature.parameters)

(secondary_constructor
  "constructor" @outline.function
  (function_value_parameters) @outline.signature.parameters)

; Values (only top-level and class-level)
(source_file
  (property_declaration
    (variable_declaration
      (simple_identifier) @outline.value)))

(class_body
  (property_declaration
    (variable_declaration
      (simple_identifier) @outline.value)))
