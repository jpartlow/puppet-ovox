# Given the host TargetSpecs for the cluster and the boolean flag for
# whether postgres is managed, returns an Ovox::TargetMap structure
# with all the computed Target arrays for installation and
# configuration. This structure can then be interrogated by other
# functions to determine topology/architecture of the cluster.
#
# @param host_map A hash of the host TargetSpecs provided for the
#   cluster.
# @param manage_postgres Flag for whether PostgreSQL (if
#   postgres_hosts are present) is managed in the cluster or is just a
#   host reference to an unmanaged PostgreSQL service outside of the
#   cluster.
function ovox::generate_target_map(
  Ovox::HostMap $host_map,
  Boolean       $manage_postgres,
) >> Ovox::TargetMap {

  # Obtain actual targets that we can perform reliable equality tests
  # on, rather than just Strings or inventory group name references.
  $server_targets      = get_targets($host_map['primary_host'])
  $compiler_targets    = get_targets($host_map['compiler_hosts'])
  $compiler_lb_targets = get_targets($host_map['compiler_lb_hosts'])
  $ovdb_targets        = get_targets($host_map['ovdb_hosts'])
  $ovdb_lb_targets     = get_targets($host_map['ovdb_lb_hosts'])
  if $manage_postgres {
    $postgres_targets = get_targets($host_map['postgres_hosts'])
    $unmanaged_postgres_hosts = []
  } else {
    $postgres_targets = []
    $unmanaged_postgres_hosts =
      Array($host_map['postgres_hosts'], true)
  }
  $agent_targets       = get_targets($host_map['agent_hosts'])

  $target_map = {
    'server_targets'           => $server_targets,
    'compiler_targets'         => $compiler_targets,
    'compiler_lb_targets'      => $compiler_lb_targets,
    'ovdb_targets'             => $ovdb_targets,
    'ovdb_lb_targets'          => $ovdb_lb_targets,
    'postgres_targets'         => $postgres_targets,
    'unmanaged_postgres_hosts' => $unmanaged_postgres_hosts,
    'agent_targets'            => $agent_targets,
  }

  $target_map
}
