# Enumeration of established Openvox Service Infrastructure roles used
# by this module and the puppet-ov_roles module.
# XXX: Probably this type should move to ov_roles? Possibly only if
# there would be an actual usage of it there.
type Ovox::Roles = Enum[
  'compiler',
  'compiler_lb',
  'ovdb',
  'ovdb_lb',
  'postgres',
  'primary',
]
