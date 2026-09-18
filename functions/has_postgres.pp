# Given a TargetMap, returns true if the cluster has some PostgreSQL
# services defined, either internally or as an external reference.
#
# @param target_map Ovox::TargetMap instance for the cluster.
# @return True if postgres services are defined.
function ovox::has_postgres(
  Ovox::TargetMap $target_map
) >> Boolean {
  # lint:ignore:strict_indent
  !($target_map['postgres_targets'].empty() and
    $target_map['unmanaged_postgres_hosts'].empty())
  # lint:endignore
}
