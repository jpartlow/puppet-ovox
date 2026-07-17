# Given a TargetMap, returns true if the cluster has compiler
# targets.
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::has_compilers(
  Ovox::TargetMap $target_map
) >> Boolean {
  ! $target_map['compiler_targets'].empty()
}
