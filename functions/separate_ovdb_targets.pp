# Returns an array of openvoxdb targets to manage that are not the
# primary openvox-server target.
#
# @param target_map The TargetMap for the cluster.
# @return Array of ovdb targets that are not the primary.
function ovox::separate_ovdb_targets(
  Ovox::TargetMap $target_map,
) >> Array[Target] {
  $target_map['ovdb_targets'] - $target_map['primary_targets']
}
