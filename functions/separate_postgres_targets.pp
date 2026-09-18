# Returns an array of PostgreSQL targets to manage that are not the
# primary openvox-server target and not a separate openvoxdb target.
#
# @param target_map The TargetMap for the cluster.
# @return
#   Array of postgres targets that are not the primary or ovdb
#   targets.
function ovox::separate_postgres_targets(
  Ovox::TargetMap $target_map,
) >> Array[Target] {
  # lint:ignore:strict_indent
  $target_map['postgres_targets'] -
    $target_map['primary_targets'] -
    $target_map['ovdb_targets']
  # lint:endignore
}
