# Returns an array of openvoxdb targets to manage that are not the
# primary openvox-server target.
#
# @param target_map The TargetMap for the cluster.
function ovox::separate_ovdb_targets(
  Ovox::TargetMap $target_map,
) >> Array[Target] {
  $target_map['ovdb_targets'] - $target_map['server_targets']
}
