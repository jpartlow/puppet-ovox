# Given a TargetMap, returns true if the cluster has a primary
# with just openvox-server, and there are no separate openvoxdb
# or PostgreSQL nodes in the cluster, and no unmanaged PostgreSQL
# configured from outside the cluster.
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::is_tinyish(
  Ovox::TargetMap $target_map,
) >> Boolean {
  ovox::has_tiny_primary($target_map) and
    ! ovox::has_separate_ovdbs($target_map) and
    ! ovox::has_separate_postgres($target_map)
}
