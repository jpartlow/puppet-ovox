# Given a TargetMap, returns true if the primary has
# openvox-server and openvoxdb services, but not PostgreSQL
# services managed on it.
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::has_large_primary(
  Ovox::TargetMap $target_map
) >> Boolean {
  $server_targets = $target_map['server_targets']
  $primary = $server_targets[0]
  $ovdb_on_primary = $target_map['ovdb_targets'].any |$t| {
    $t == $primary
  }
  $postgres_not_on_primary = $target_map['postgres_targets'].all |$t| {
    $t != $primary
  }

  $ovdb_on_primary and
    $postgres_not_on_primary and
    ($server_targets.size() == 1)
}
