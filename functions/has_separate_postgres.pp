# Given a TargetMap, returns true if the cluster has
# postgres services that are not on the primary.
#
# This could be either cluster nodes with PostgreSQL managed by the
# module, or some external unmanaged PostgreSQL service in the cloud.
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::has_separate_postgres(
  Ovox::TargetMap $target_map
) >> Boolean {
  # Either we are explicitly managing a separate postgres node,
  (! $target_map['separate_postgres_targets'].empty()) or
  # We have a reference to an unmanaged postgres host somewhere in
  # the cloud to configure against.
    (! $target_map['manage_postgres'] and
     ! $target_map['postgres_hosts'].empty())
}
