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
  Boolean        $manage_postgres,
) >> Ovox::TargetMap {

  # Obtain actual targets that we can perform reliable equality tests
  # on, rather than just Strings or inventory group name references.
  $primary_target      = get_target($host_map['primary_host'])
  $server_targets      = [$primary_target]
  $compiler_targets    = get_targets($host_map['compiler_hosts'])
  $compiler_lb_targets = get_targets($host_map['compiler_lb_hosts'])
  $ovdb_targets        = get_targets($host_map['ovdb_hosts'])
  $ovdb_lb_targets     = get_targets($host_map['ovdb_lb_hosts'])
  $postgres_targets    = $manage_postgres ? {
    false   => [],
    default => get_targets($host_map['postgres_hosts'])
  }
  $agent_targets       = get_targets($host_map['agent_hosts'])

  $separate_ovdb_targets = $ovdb_targets - $server_targets
  $separate_postgres_targets = $postgres_targets - $server_targets - $ovdb_targets

  # All nodes that need to be earmarked for agent installation so that
  # we can later manage them with OpenVox. The openvox nodes (server,
  # ovdb, compiler) all get agents installed prior to their service
  # packages being installed as a matter of course.
  $all_agent_targets = [
    $agent_targets,
    $compiler_lb_targets,
    $ovdb_lb_targets,
    $separate_postgres_targets,
  ].flatten().unique()

  $target_map = {
    'primary_target'               => $primary_target,
    'server_targets'               => $server_targets,
    'compiler_targets'             => $compiler_targets,
    'compiler_lb_targets'          => $compiler_lb_targets,
    'ovdb_targets'                 => $ovdb_targets,
    'ovdb_lb_targets'              => $ovdb_lb_targets,
    'postgres_targets'             => $postgres_targets,
    'agent_targets'                => $agent_targets,
    'separate_ovdb_targets'        => $separate_ovdb_targets,
    'separate_postgres_targets'    => $separate_postgres_targets,
    'all_additional_agent_targets' => $all_agent_targets,
    'manage_postgres'              => $manage_postgres,
    # Ensure an array is returned.
    'postgres_hosts'               => Array($host_map['postgres_hosts'], true),
  }

  $target_map
}
