# Return the address to the PostgreSQL server that Openvoxdb instances
# should connect to.
#
# If there are no postgres_targets, it will return the first
# unmanaged_postgres_host entry.
#
# If there is a single postgres target, and ovdb_targets is the same
# single target, then it will return localhost.
#
# Otherwise, the first postgres_target address will be returned.
#
# It may return undef if no postgres host information is configured.
#
# This function does not address complex configuration scenarios with
# multiple postgres targets.
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::get_postgres_address(
  Ovox::TargetMap $target_map,
) >> Optional[String] {
  $postgres_targets = $target_map['postgres_targets']
  case $postgres_targets.length() {
    0: { $target_map['unmanaged_postgres_hosts'][0] }
    1: {
      ($postgres_targets == $target_map['ovdb_targets']) ? {
        true    => 'localhost',
        default => $postgres_targets[0].name(),
      }
    }
    default: {
      $postgres_targets[0].name()
    }
  }
}
