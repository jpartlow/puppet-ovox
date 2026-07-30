# Given a TargetMap, returns true if the primary has
# openvox-server and openvoxdb services, but not PostgreSQL
# services managed on it.
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::has_large_primary(
  Ovox::TargetMap $target_map
) >> Boolean {
  $ovdb_on_primary =
    ovox::role_includes('primary', 'ovdb', $target_map)
  $postgres_not_on_primary =
    ! ovox::role_includes('primary', 'postgres', $target_map)

  $ovdb_on_primary and
    $postgres_not_on_primary
}
