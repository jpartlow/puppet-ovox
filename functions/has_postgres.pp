# Given a TargetMap, returns true if the cluster has some PostgreSQL
# services defined, either internally or as an external reference.
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::has_postgres(
  Ovox::TargetMap $target_map
) >> Boolean {
  (!$target_map['postgres_hosts'].empty())
}
