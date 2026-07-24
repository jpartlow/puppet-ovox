# Given cluster host information, validate the architecture and
# return an Ovox::TargetMap structure with Target arrays
# and host configuration info for the rest of the plan to work
# with.
#
# May raise errors for invalid configurations.
#
# TODO: May raise warnings and pause for confirmation.
plan ovox::subplans::determine_architecture(
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

  $errors = ovox::validate_architecture($target_map)

  if !$errors.empty() {
    fail_plan(@("EOS"))
      Errors found in cluster definition:
      ${errors.join("\n")}
      |- EOS
  }

  return $target_map
}
