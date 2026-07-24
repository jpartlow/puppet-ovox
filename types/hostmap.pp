# Structured map of TargetSpec host inputs, along with the
# compiler/ovdb_pool_address hostnames if given, for the
# ovox::generate_target_map() function.
#
# These TargetSpecs are parameters of the ovox::install plan.
type Ovox::HostMap = Struct[{
  primary_host          => BoltLib::TargetSpec,
  ovdb_hosts            => BoltLib::TargetSpec,
  postgres_hosts        => BoltLib::TargetSpec,
  compiler_hosts        => BoltLib::TargetSpec,
  compiler_lb_hosts     => BoltLib::TargetSpec,
  ovdb_lb_hosts         => BoltLib::TargetSpec,
  agent_hosts           => BoltLib::TargetSpec,
  compiler_pool_address => Optional[String[1]],
  ovdb_pool_address     => Optional[String[1]],
}]
