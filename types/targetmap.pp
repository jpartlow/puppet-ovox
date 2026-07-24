# This structure provides a consistent mapping of Target arrays
# as returned by the ovox::generate_target_map() function.
#
# It allows a host of other small functions to return consistent
# answers about the cluster architecture, and provides Bolt::Targets
# for the rest of the plans to operate on.
#
# Keys:
# - server_targets: An array of one Target object pointing to the
#   cluster's primary host (openvox-server/ca). This is an array
#   for consistency of handling, but must have one and only one
#   target.
# - ovdb_targets: An array of the openvoxdb host targets.
# - ovdb_lb_targets: An array of any load-balancers for the
#   openvoxdb hosts.
# - postgres_targets: An array of PostgreSQL server targets for the
#   openvoxdb service.
# - compiler_targets: An array of openvox-server compiler hosts.
# - compiler_lb_targets: An array of any load-balancers for the
#   compilers.
# - agent_targets: An array of any additional cluster hosts that
#   the openvox-agent is to be installed on. (typically used by test
#   suites...)
# - unmanaged_postgres_hosts: A TargetSpec of the original postgres host
#   information passed into the plan if the $manage_postgres flag is
#   false. Since the plan can handle either postgres managed or unmanaged
#   we have the following states:
#
#   1) neither $postgres_targets nor $unmanaged_postgres_targets set:
#   no postgres, so no ovdb, in the cluster
#   2) managed $postgres_targets for ovdb in the cluster
#   3) $unmanaged_postgres_targets for ovdb to be configured against,
#   that are hosted outside of the cluster and configured entirely
#   separately (most likely a cloud db)
#
#   The ovox::get_target_map() function will not return a TargetMap
#   with both $postgres_targets and $unmanaged_postgres_targets. A
#   TargetMap in such a state is an error.
type Ovox::TargetMap = Struct[{
  server_targets           => Array[Target,1,1],
  ovdb_targets             => Array[Target],
  ovdb_lb_targets          => Array[Target],
  postgres_targets         => Array[Target],
  compiler_targets         => Array[Target],
  compiler_lb_targets      => Array[Target],
  agent_targets            => Array[Target],
  unmanaged_postgres_hosts => BoltLib::TargetSpec,
}]
