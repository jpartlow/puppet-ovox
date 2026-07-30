# Given a TargetMap, returns true if the primary has
# openvox-server, openvoxdb and PostgreSQL Services managed on it.
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::has_small_primary(
  Ovox::TargetMap $target_map
) >> Boolean {
  $primary_targets = $target_map['primary_targets']
  $primary = $primary_targets[0]
  $ovdb_on_primary = $target_map['ovdb_targets'].any |$t| {
    $t == $primary
  }
  $postgres_on_primary = $target_map['postgres_targets'].any |$t| {
    $t == $primary
  }

  $ovdb_on_primary and
    $postgres_on_primary and
    ($primary_targets.size() == 1)
}
