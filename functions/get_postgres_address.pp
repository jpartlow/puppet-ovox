# Get the address to the PostgreSQL server that Openvoxdb instances
# should connect to.
#
# This function does not address complex configuration scenarios with
# multiple postgres targets.
#
# It returns the first *postgres_targets* entry.
#
# If there are no *postgres_targets*, it will return the first
# *unmanaged_postgres_hosts* entry.
#
# It may return undef if no postgres host information is configured.
#
# @param target_map Ovox::TargetMap instance for the cluster.
# @return The Postgresql service address for the cluster or undef.
function ovox::get_postgres_address(
  Ovox::TargetMap $target_map,
) >> Optional[String] {
  $postgres_targets = $target_map['postgres_targets']
  case $postgres_targets.length() {
    0: { $target_map['unmanaged_postgres_hosts'][0] }
    default: {
      $postgres_targets[0].name()
    }
  }
}
