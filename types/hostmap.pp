# Structured map of TargetSpec host inputs for the
# ovox::generate_target_map() function.
#
# These TargetSpecs are parameters of the ovox::install plan.
type Ovox::HostMap = Struct[{
  primary_host      => BoltLib::TargetSpec,
  ovdb_hosts        => BoltLib::TargetSpec,
  postgres_hosts    => BoltLib::TargetSpec,
  compiler_hosts    => BoltLib::TargetSpec,
  compiler_lb_hosts => BoltLib::TargetSpec,
  ovdb_lb_hosts     => BoltLib::TargetSpec,
  agent_hosts       => BoltLib::TargetSpec,
}]
