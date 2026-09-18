# Given a TargetMap, returns true if the primary has all three
# openvox-server, openvoxdb and PostgreSQL services, and there are
# no other openvoxdb or PostgreSQL targets in the cluster.
#
# @param target_map Ovox::TargetMap instance for the cluster.
# @return
#   True if cluster primary services match a small architecture.
function ovox::is_smallish(
  Ovox::TargetMap $target_map,
) >> Boolean {
  # lint:ignore:strict_indent
  ovox::has_small_primary($target_map) and
    ! ovox::has_separate_ovdbs($target_map) and
    ! ovox::has_separate_postgres($target_map)
  # lint:endignore
}
