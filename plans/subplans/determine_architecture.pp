# Determine architecture, role mappings and configuration from given
# host targets and return a hash of information for the caller.
#
# May raise warnings and pause for confirmation.
#
# May raise errors for invalid configurations.
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
      'primary_host'      => $primary_host,
      'ovdb_hosts'        => $ovdb_hosts,
      'postgres_hosts'    => $postgres_hosts,
      'compiler_hosts'    => $compiler_hosts,
      'compiler_lb_hosts' => $compiler_lb_hosts,
      'ovdb_lb_hosts'     => $ovdb_lb_hosts,
      'agent_hosts'       => $agent_hosts,
    },
    $manage_postgres,
  )

  $architecture = ovox::get_architecture($target_map)

  if $architecture == 'custom' {
    $arch_errs = [
      [
        $target_map['server_targets'].empty(),
        'No defined primary openvox-server targets.',
      ],
      [
        (ovox::has_postgres($target_map) and
          $target_map['ovdb_targets'].empty()),
        'Postgres nodes defined, but no ovdb nodes in cluster.'
      ],
      [
        (!$target_map['ovdb_targets'].empty() and
          !ovox::has_postgres($target_map)) ,
        'Openvoxdb nodes defined, but no Postgres nodes in cluster.'
      ],
      [
        (!$target_map['compiler_targets'].empty() and
          $target_map['compiler_lb_targets'].empty() and
          $compiler_pool_address !~ String[1]),
        @(EOS/L),
          Compilers defined but no compiler load-balancer nodes \
          or compiler_pool_address is set.
          |- EOS
      ],
      [
        (($target_map['ovdb_targets'].count() > 1) and
          $target_map['ovdb_lb_targets'].empty() and
          $ovdb_pool_address !~ String[1]),
        @(EOS/L),
          Multiple Openvoxdb nodes defined, but no openvoxdb \
          load-balanacer nodes or ovdb_pool_address is set.
          |- EOS
      ],
      # This shouldn't be possible based on how generate_target_map()
      # works...
      [
        (!$target_map['postgres_targets'].empty() and
         !$target_map['manage_postgres']),
        'Both internal and external PostgreSQL has been defined.',
      ],
    ].reduce([]) |$errors, $i| {
      $test = $i[0]
      $errmsg = $i[1]
      $test ? {
        true    => $errors + [$errmsg],
        default => $errors,
      }
    }
  } else {
    $arch_errs = []
  }

  # Maps the OpenVox ov_role classes to the distinct set of targets
  # they will be classifying in the configuration phase.
  $role_map = ovox::derive_role_map($target_map)

  # Check for invalid role intersections.
  $role_intersection_errors = [
    'compiler',
    'compiler_lb',
    'ovdb_lb',
  ].reduce([]) |$errors, $role| {
    $intersection_errs =
      ovox::check_role_target_intersection($role, $role_map)
    $intersection_errs.empty() ? {
      false   => $errors + $intersection_errors,
      default => $errors,
    }
  }

  $errors = $arch_errs + $role_intersection_errors

  if !$errors.empty() {
    fail_plan(@("EOS"))
      Errors found in cluster definition:
      ${errors.join("\n")}
      |- EOS
  }

  $final_arch_map = {
    'architecture' => $architecture,
    'target_map'   => $target_map,
    'role_map'     => $role_map,
  }
  return $final_arch_map
}
