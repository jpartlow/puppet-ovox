# Given a TargetMap, returns true if the primary has only openvox-server
# and openvoxdb services, the cluster has a separate postgres node or
# external service, but there are no additional openvoxdb nodes in the
# cluster.
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::is_largish(
  Ovox::TargetMap $target_map,
) >> Boolean {
  ovox::has_large_primary($target_map) and
    ! ovox::has_separate_ovdbs($target_map) and
    ovox::has_separate_postgres($target_map)
}
