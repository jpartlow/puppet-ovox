# This structure provides a consistent mapping of Target arrays
# as returned by the ovox::generate_target_map() function.
#
# It allows a host of other small functions to return consistent
# answers about the cluster architecture when supplied this single
# input.
#
# Keys:
# - primary_target: A Target object pointing to the cluster's primary
#   host (openvox-server/ca).
# - server_targets: [primary_target]
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
# - separate_ovdb_targets: A computed array of ovdb_targets that are
#   not server_targets. (So, separate openvoxdb nodes...)
# - separate_postgres_targets: A computed array of postgres_targets
#   that are not server or ovdb_targets. (So, separate, managed
#   PostgreSQL nodes).
# - all_additional_agent_targets: A computed array of all additional
#   targets the plan must ensure the openvox-agent is installed on.
#   They can then be managed in the configure stage.
#
#   In addition to user requested agent_targets, this will
#   include all *_lb_targets, and separate_postgres_targets.
# 
#   (Any target receiving openvox service packages will also
#   automatically have the openvox-agent installed upon it by the
#   plan.)
# - manage_postgres: A flag indicating that postgres hosts in this
#   cluster are to be managed. If false, then any postgres_hosts are
#   assumed to be managed outside of the cluster, and postgres_targets
#   will be an empty array.
# - postgres_hosts: A TargetSpec of the original postgres host
#   information passed into the plan. Since postgres can be either
#   managed or unmanaged, the postgres_hosts field, along with
#   manage_postgres and postgres_targets allows three states to be
#   sorted:
#
#   1) no postgres, so no ovdb, in the cluster
#   2) managed postgres targets for ovdb in the cluster
#   3) unmanaged postgres targets for ovdb to be configured against,
#   that are hosted outside of the cluster and configured entirely
#   separately (most likely a cloud db)
#
type Ovox::TargetMap = Struct[{
  primary_target               => Target,
  server_targets               => Array[Target],
  ovdb_targets                 => Array[Target],
  ovdb_lb_targets              => Array[Target],
  postgres_targets             => Array[Target],
  compiler_targets             => Array[Target],
  compiler_lb_targets          => Array[Target],
  agent_targets                => Array[Target],
  separate_ovdb_targets        => Array[Target],
  separate_postgres_targets    => Array[Target],
  all_additional_agent_targets => Array[Target],
  manage_postgres              => Boolean,
  postgres_hosts               => BoltLib::TargetSpec,
}]
