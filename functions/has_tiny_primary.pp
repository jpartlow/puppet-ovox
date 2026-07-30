# Given a TargetMap, returns true if the primary just as the
# openvox-server service.
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::has_tiny_primary(
  Ovox::TargetMap $target_map
) >> Boolean {
  $primary_targets = $target_map['primary_targets']
  $no_ovdb =
    intersection($primary_targets, $target_map['ovdb_targets']).empty()
  $no_postgres =
    intersection(
      $primary_targets,
      $target_map['postgres_targets']
    ).empty()

  $no_ovdb and $no_postgres and ($primary_targets.size() == 1)
}
