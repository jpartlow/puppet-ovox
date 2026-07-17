# Given a TargetMap, returns true if the primary just as the
# openvox-server service.
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::has_tiny_primary(
  Ovox::TargetMap $target_map
) >> Boolean {
  $server_targets = $target_map['server_targets']
  ($server_targets != $target_map['ovdb_targets']) and
    ($server_targets != $target_map['postgres_targets']) and
    ($server_targets.size() == 1)
}
