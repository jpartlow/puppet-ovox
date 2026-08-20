# Validate the given cluster TargetMap for architectural and role
# errors and return an array of any errors found.
#
# There are constraints to what constitutes a valid cluster based on
# the plan being able to successful install, configure and test the
# cluster by running the agent on all nodes.
#
# The function returns three classes of issues:
#
# * Warnings, which are informational but shouldn't affect the module
#   workflow.
# * Ambiguities, which reflect configuration problems like defining multiple
#   primary are postgresql nodes. These issues prevent the module from
#   automatically generating hiera configuration and require manual
#   hiera data to be added before application of the catalogs can
#   complete successfully.
# * Errors, which reflect structural problems preventing
#   classification of the given cluster nodes into discrete roles.
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::validate_architecture(
  Ovox::TargetMap $target_map,
) >> Ovox::ArchErrors {

  ##########
  # Warnings

  $arch_warnings = [
    # Allow for just agent maps.
    [
      $target_map['primary_targets'].empty(),
      'No defined primary openvox-server targets.',
    ],
    [
      !ovox::separate_ovdb_targets($target_map).empty() and
        !intersection(
          $target_map['primary_targets'],
          $target_map['postgres_targets']
        ).empty(),
      @(EOS/L),
        Primary has postgresql, but openvoxdb is on a separate \
        node(s). This is likely less efficient than moving postgresql
        to a separate node.
        |- EOS
    ],
  ].reduce([]) |$warnings, $i| {
    $test = $i[0]
    $msg = "Warning: ${i[1]}"
    $test ? {
      true    => $warnings + [$msg],
      default => $warnings,
    }
  }

  #############
  # Ambiguities

  $arch_ambiguities = [
    [
      ($target_map['primary_targets'].length > 1),
      'More than one primary (certificate authority).',
    ],
    [
      ($target_map['postgres_targets'].length > 1),
      'More than one PostgreSQL target.',
    ],
    [
      (ovox::has_postgres($target_map) and
        $target_map['ovdb_targets'].empty()),
      'Postgres nodes defined, but no openvoxdb nodes in cluster.',
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
    $errmsg = "Ambiguity: ${i[1]}"
    $test ? {
      true    => $errors + [$errmsg],
      default => $errors,
    }
  }

  #------------------------------------
  # Non-uniform primary, or ovdb roles.

  $primary_targets  = $target_map['primary_targets']
  $ovdb_targets     = $target_map['ovdb_targets']
  $postgres_targets = $target_map['postgres_targets']
  $separate_ovdb_targets = ovox::separate_ovdb_targets($target_map)

  $role_profile_ambiguities = [
    [
      ['Openvoxdb',  $separate_ovdb_targets],
      ['PostgreSQL', $postgres_targets],
    ],
    [
      ['Primary',   $primary_targets],
      ['Openvoxdb', $ovdb_targets],
    ],
    [
      ['Primary',    $primary_targets],
      ['PostgreSQL', $postgres_targets],
    ],
  ].reduce([]) |$errors, $targets| {
    $t1_label = dig($targets, 0, 0)
    $t1       = dig($targets, 0, 1)
    $t2_label = dig($targets, 1, 0)
    $t2       = dig($targets, 1, 1)
    $consistent_profiles = (
      ovox::disjoint($t1, $t2) or
      ovox::subset_of($t1, $t2)
    )
    $errmsg = @("EOS"/L)
      Ambiguity: Only some ${t1_label} targets (${t1}) are \
      also ${t2_label} targets (${t2}). ${t1_label} \
      targets must either be disjoint from ${t2_label} targets, \
      or a subset of $t2_label} targets.
      |- EOS
    !$consistent_profiles ? {
      true    => $errors + $errmsg,
      default => $errors,
    }
  }

  ########
  # Errors

  #------------------
  # Overlapping roles

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

  $arch_messages = {
    'warnings'    => $arch_warnings,
    'ambiguities' => $arch_ambiguities + $role_profile_ambiguities,
    'errors'      => $role_intersection_errors,
  }
  $arch_messages
}
