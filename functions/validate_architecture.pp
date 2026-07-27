# Validate the given cluster TargetMap for architectural and role
# errors and return an array of any errors found.
#
# There are constraints to what constitutes a valid cluster based on
# the plan being able to successful install, configure and test the
# cluster by running the agent on all nodes.
#
# * There must be a primary openvox-server defined.
# * If openvoxdb nodes are defined, there most be a postgres node
# defined or a host reference to an external postgres.
# * Likewise, if there is a postgres reference, there must be
# openvoxdb nodes defined.
# * If there are compilers, then there must be a compiler
# load-balancer node, or a $compiler_pool_address reference.
# * And if there is more than one openvoxdb node, there likewise must
# be an openvoxdb load-balancer node or a $ovdb_pool_address
# reference.
# * Overlapping compiler or load-balancer roles with another primary
# role (primary, ovdb, postgres...).
#
# TODO: Warnings, for grey areas like splitting ovdb nodes across the
# primary and additional nodes. Odd configurations like a primary with
# openvox-server, postgres and a separate ovdb node... Things that
# should technically work but are probably a bad idea or an
# unnecessary complication...
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::validate_architecture(
  Ovox::TargetMap $target_map,
) >> Array[String[1]] {

  # TODO: not doing anything with these yet. Need to change the
  # returned structure, for one thing.
  $arch_warnings = [
    # Allow for just agent maps.
    [
      $target_map['server_targets'].empty(),
      'No defined primary openvox-server targets.',
    ],
  ]

  $arch_errs = [
    [
      (ovox::has_postgres($target_map) and
        $target_map['ovdb_targets'].empty()),
      'Postgres nodes defined, but no openvoxdb nodes in cluster.'
    ],
    [
      (!$target_map['ovdb_targets'].empty() and
        !ovox::has_postgres($target_map)) ,
      @(EOS/L),
        Openvoxdb nodes defined, but no Postgres nodes defined \
        or referenced, managed or unmanaged.
        |- EOS
    ],
    [
      (!$target_map['compiler_targets'].empty() and
        (ovox::get_pool_address('compiler', $target_map) =~ Undef)),
      @(EOS/L),
        Compilers defined, but no compiler load-balancer nodes \
        or compiler_pool_address is set.
        |- EOS
    ],
    [
      (($target_map['ovdb_targets'].count() > 1) and
        (ovox::get_pool_address('ovdb', $target_map) =~ Undef)),
      @(EOS/L),
        Multiple Openvoxdb nodes defined, but no openvoxdb \
        load-balancer nodes or ovdb_pool_address is set.
        |- EOS
    ],
    # This shouldn't be possible based on how generate_target_map()
    # works, but a manually constructed TargetMap could still
    # violate this constraint...
    [
      (!$target_map['postgres_targets'].empty() and
       !$target_map['unmanaged_postgres_hosts'].empty()),
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

  # Maps the OpenVox ov_role classes to the distinct set of targets
  # they will be classifying in the configuration phase.
  $role_map = ovox::derive_role_map($target_map)

  # Check for invalid role intersections.
  $role_intersection_errors = [
    'compiler',
    'compiler_lb',
    'ovdb_lb',
  ].reduce([]) |$errors, $role| {
    $intersection_errors =
      ovox::check_role_target_intersection($role, $role_map)
    $intersection_errors.empty() ? {
      false   => $errors + $intersection_errors,
      default => $errors,
    }
  }

  $arch_errs + $role_intersection_errors
}
