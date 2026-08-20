# Structure returned by the ovox::validate_architecture() function.
#
# Keys:
# - warnings: informational warnings about the architecture.
# - ambituities: issues that will prevent auto-configuration.
# - errors: structural problems that will halt the workflow during the
#   architecture validation stage.
type Ovox::ArchErrors = Struct[{
  warnings    => Array[String[1]],
  ambiguities => Array[String[1]],
  errors      => Array[String[1]],
}]
