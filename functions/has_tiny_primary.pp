# Given a TargetMap, returns true if the primary just as the
# openvox-server service.
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::has_tiny_primary(
  Ovox::TargetMap $target_map
) >> Boolean {
  $no_ovdb =
    ! ovox::role_includes('primary', 'ovdb', $target_map)
  $no_postgres =
    ! ovox::role_includes('primary', 'postgres', $target_map)

  $no_ovdb and $no_postgres
}
