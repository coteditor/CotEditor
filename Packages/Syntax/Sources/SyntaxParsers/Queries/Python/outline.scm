;
;  outline.scm
;  for Python
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; Containers
(class_definition
  name: (identifier) @outline.container)

; Functions
(function_definition
  name: (identifier) @outline.function
  parameters: (parameters) @outline.signature.parameters)
