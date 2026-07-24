# Given a TargetMap, returns true if the cluster has openvoxdb
# services that are not on the primary.
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::has_separate_ovdbs(
  Ovox::TargetMap $target_map
) >> Boolean {
  ! ovox::separate_ovdb_targets($target_map).empty()
}
