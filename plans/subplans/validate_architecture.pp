# Given cluster host information, validate the architecture and
# return an Ovox::TargetMap structure with Target arrays
# and host configuration info for the rest of the plan to work
# with.
#
# May raise errors for invalid configurations.
#
# May raise warnings and pause for confirmation.
#
# @param primary_host The primary openvox-server and
#   certificate-authority host for the cluster.
# @param ovdb_hosts Array of openvoxdb hosts.
# @param postgres_hosts Array of postgres hosts.
# @param compiler_hosts Array of openvox-server compiler hosts.
# @param compiler_lb_hosts Array of haproxy load-balancers for the
#   compiler hosts.
# @param ovdb_lb_hosts Array of haproxy load-balancers for the ovdb
#   hosts.
# @param agent_hosts Array of non-infrastructure agent hosts.
# @param manage_postgres Whether postgresql will be installed and
#   configured on *postgres_hosts*.
# @param compiler_pool_address Optional hostname for the compiler load
#   balancer.
# @param ovdb_pool_address Optional hostname for the ovdb load
#   balancer.
plan ovox::subplans::validate_architecture(
  TargetSpec $primary_host,
  TargetSpec $ovdb_hosts,
  TargetSpec $postgres_hosts,
  TargetSpec $compiler_hosts,
  TargetSpec $compiler_lb_hosts,
  TargetSpec $ovdb_lb_hosts,
  TargetSpec $agent_hosts,
  Boolean $manage_postgres,
  Optional[String[1]] $compiler_pool_address = undef,
  Optional[String[1]] $ovdb_pool_address = undef,
) {

  $target_map = ovox::generate_target_map(
    {
      'primary_host'          => $primary_host,
      'ovdb_hosts'            => $ovdb_hosts,
      'postgres_hosts'        => $postgres_hosts,
      'compiler_hosts'        => $compiler_hosts,
      'compiler_lb_hosts'     => $compiler_lb_hosts,
      'ovdb_lb_hosts'         => $ovdb_lb_hosts,
      'agent_hosts'           => $agent_hosts,
      'compiler_pool_address' => $compiler_pool_address,
      'ovdb_pool_address'     => $ovdb_pool_address,
    },
    $manage_postgres,
  )

  $architecture = ovox::get_architecture($target_map)
  out::message("Architecture: ${architecture}")

  $info = ovox::validate_architecture($target_map)

  $info['warnings'].each |$w| {
    log::info($w)
  }

  if !$info['ambiguities'].empty() {
    out::message(@(EOS))
      The configured architecture is ambiguous, which means the module
      is not capable of automatically generating the hiera data needed
      to configure nodes. You will need to provide manual hiera data
      to configure this cluster (please see the docs).

      The following issues were noted:
      | EOS
    $info['ambiguities'].each |$a| {
      log::warning($a)
    }
    # TODO: Need to wire in an ignore warnings flag.
    $response = prompt('Continue executing plan? [y\[n]]')
    if ($response != 'y') and ($response != 'Y') {
      fail_plan('Aborting ambiguous architecture run.')
    }
  }

  if !$info['errors'].empty() {
    fail_plan(@("EOS"))
      Errors found in cluster definition:
      ${info['errors'].join("\n")}
      |- EOS
  }

  return $target_map
}
