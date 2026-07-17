# Given a TargetMap, returns true if the primary has only
# openvox-server, and the cluster has separate openvoxdb
# nodes and either separate or unmanaged postgres nodes.
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::is_hugish(
  Ovox::TargetMap $target_map,
) >> Boolean {
  ovox::has_tiny_primary($target_map) and
    ovox::has_separate_ovdbs($target_map) and
    ovox::has_separate_postgres($target_map)
}
