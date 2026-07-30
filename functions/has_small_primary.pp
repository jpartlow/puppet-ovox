# Given a TargetMap, returns true if the primary has
# openvox-server, openvoxdb and PostgreSQL Services managed on it.
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::has_small_primary(
  Ovox::TargetMap $target_map
) >> Boolean {
  $ovdb_on_primary =
    ovox::role_includes('primary', 'ovdb', $target_map)
  $postgres_on_primary =
    ovox::role_includes('primary', 'postgres', $target_map)

  $ovdb_on_primary and $postgres_on_primary
}
