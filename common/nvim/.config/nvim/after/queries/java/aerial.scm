; extends

(record_declaration
  name: (identifier) @name
  (#set! "kind" "Class")) @symbol

(compact_constructor_declaration
  name: (identifier) @name
  (#set! "kind" "Constructor")) @symbol
