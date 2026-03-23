;
;  outline.scm
;  for SQL
;
;  CotEditor
;  https://coteditor.com
;
;  © 2026 1024jp
;

; Containers
(create_database
  name: (identifier) @outline.container)

(create_schema
  (identifier) @outline.container)

(create_table
  (object_reference
    name: (identifier) @outline.container))

(create_view
  (object_reference
    name: (identifier) @outline.container))

(create_materialized_view
  (object_reference
    name: (identifier) @outline.container))

(create_index
  (object_reference
    name: (identifier) @outline.container))

(create_trigger
  (object_reference
    name: (identifier) @outline.container))

(create_type
  (object_reference
    name: (identifier) @outline.container))

(create_sequence
  (object_reference
    name: (identifier) @outline.container))

(alter_table
  (object_reference
    name: (identifier) @outline.container))

(alter_view
  (object_reference
    name: (identifier) @outline.container))

(alter_index
  (identifier) @outline.container)

(drop_table
  (object_reference
    name: (identifier) @outline.container))

(drop_view
  (object_reference
    name: (identifier) @outline.container))

(drop_index
  (object_reference
    name: (identifier) @outline.container))

(drop_function
  (object_reference
    name: (identifier) @outline.container))

(drop_procedure
  (object_reference
    name: (identifier) @outline.container))

; Functions
(create_function
  (object_reference) @outline.function
  (function_arguments) @outline.signature.arguments)

(create_procedure
  (object_reference) @outline.function
  ((function_arguments) @outline.signature.arguments)?)
