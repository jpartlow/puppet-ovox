# This structure provides a consistent mapping of Target arrays
# and a few hostname references for an OpenVox service cluster
# as returned by the ovox::generate_target_map() function.
#
# It allows a host of other small functions to return consistent
# answers about the cluster architecture, and provides Bolt::Targets
# for the rest of the plans to operate on.
#
# Keys:
# - primary_targets: An array primary host (openvox-server/ca) targets.
#   This must be a single primary for auto-configuration. If more than
#   one primary is specified, then the cluster's hiera data must be
#   manually configured.
# - ovdb_targets: An array of the openvoxdb host targets.
# - ovdb_lb_targets: An array of any load-balancers for the
#   openvoxdb hosts.
# - postgres_targets: An array of PostgreSQL server targets for the
#   openvoxdb service. This must be a single target for
#   auto-configuration. If more than one postgres target is specified,
#   then the cluster's hiera data must be manually configured.
# - compiler_targets: An array of openvox-server compiler hosts.
# - compiler_lb_targets: An array of any load-balancers for the
#   compilers.
# - agent_targets: An array of any additional cluster hosts that
#   the openvox-agent is to be installed on. (typically used by test
#   suites...)
# - unmanaged_postgres_hosts: A TargetSpec of the original postgres host
#   information passed into the plan if the $manage_postgres flag is
#   false. Since the plan can handle either postgres managed or
#   unmanaged we have the following states:
#
#   1) neither $postgres_targets nor $unmanaged_postgres_hosts set:
#   no postgres, so no ovdb, in the cluster
#   2) managed $postgres_targets for ovdb in the cluster
#   3) $unmanaged_postgres_hosts for ovdb to be configured against,
#   that are hosted outside of the cluster and configured entirely
#   separately (most likely a cloud db)
#
#   The ovox::get_target_map() function will not return a TargetMap
#   with both $postgres_targets and $unmanaged_postgres_hosts. A
#   TargetMap in such a state is an error.
# - compiler_pool_address: the hostname agents should use to reach
#   compiler services. Calculated from compiler_lb_targets (hostname
#   of first entry) if not given.
# - ovdb_pool_address: the hostname openvox-servers in the cluster
#   should use to reach openvoxdb if ovdb_targets is greater than one.
#   Calculated from ovdb_lb_targets (hostname of first entry) if not
#   given.
type Ovox::TargetMap = Struct[{
  primary_targets          => Array[Target],
  ovdb_targets             => Array[Target],
  ovdb_lb_targets          => Array[Target],
  postgres_targets         => Array[Target],
  compiler_targets         => Array[Target],
  compiler_lb_targets      => Array[Target],
  agent_targets            => Array[Target],
  unmanaged_postgres_hosts => BoltLib::TargetSpec,
  compiler_pool_address    => Optional[String[1]],
  ovdb_pool_address        => Optional[String[1]],
}]
