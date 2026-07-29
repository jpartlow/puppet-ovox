plan ovox::subplan::configure(
    Ovox::TargetMap $target_map,
    Array[String[1]] $dns_alt_names = [],
    Optional[Ovox::Postgres_version] $postgres_version = undef,
    Hash $postgres_credentials = {},
) {
  # TargetMap type has a singular server_targets array.
  $primary = $target_map['server_targets'][0]
  # Non-infrastructure agents
  $agent_targets = $target_map['agent_targets']
  $all_targets = ovox::all_agent_targets($target_map)
  $infrastructure_targets = $all_targets - $agent_targets
  $role_map = ovox::derive_role_map($target_map)

  # openvox_bootstrap::configure to set puppet.conf and csr

  # First we have to configure infrastructure nodes

  $infra_configure_results = run_task_with('openvox_bootstrap::configure',
    $infrastructure_targets
  ) |$target| {
    $role = ovox::get_role($target, $role_map)

    $task_params = {
      'puppet_conf' => {
        'main' => {
          'server' => $primary.host(),
        },
      },
      'csr_attributes' => {
        'extension_requests' => {
          'pp_role' => $role,
        }
      },
      'puppet_service_running' => false,
    }

    $task_params
  }

  out::message($infra_configure_results)

  # generate profile flags for role specialization
  $profile_flags = ovox::derive_profile_flags($target_map)
  $hiera_map = {
    # profile flags
  }
  # write local hiera config
  $hiera_root = find_file('ovox/../data')
  $hiera_layer = "${hiera_root}/clusters/${cluster_id}.yaml"
  file::write($hiera_layer, $hiera_map)

  $infrastructure_targets.each() |$t| {
    set_var($t, 'role', ovox::get_role($t))
  }

  # apply roles to nodes in stages
  [
    # separate postgres should be up before ovdb
    $role_map['postgres'],
    # XXX There may not be much reason to separate these three stages?
    # primary, separate openvoxdb
    $role_map['primary'] + $role_map['ovdb'],
    # compilers
    $role_map['compilers'],
    # load balancers
    $role_map['compiler_lb'] + $role_map['ovdb_lb'],
  ].each() |$targets| {
    # could set $role as a target.vars[] value,
    # or could run each role in a separate apply...
    apply($targets) {
      include("ov_role::${role}")
    }
  }

  # We can now setup puppet.conf on any pure agent nodes to point to
  # the compilers.
  # compiler_pool_address or clb[0] or primary if no compilers...
  $agent_server = pick(ovox::get_pool_address('compiler', $target_map), $primary.host())
  $agent_configure_results = run_task('openvox_bootstrap::configure',
    $agent_targets,
    'puppet_conf' => {
      'main' => {
        'server' => $primary.host(),
      },
    },
    'puppet_service_running' => false,
  )

  # setup primary ovox-control control repository

  # Validate agent runs

  # Ensure agent service is started and enabled.
  $agent_service_results = run_task('openvox_bootstrap::configure',
    $all_targets,
    'puppet_service_running' => true,
    'puppet_service_enabled' => true,
  )
}
