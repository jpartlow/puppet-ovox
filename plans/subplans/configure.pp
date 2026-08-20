# Configure all services for the cluster.
#
# Also involves installation of services such as PostgreSQL, HAProxy
# and such.
#
# This plan basically runs through the following phases:
#
# 1. Configure puppet.conf and csr_attributes.yaml on infrastructure
#    nodes.
#  * puppet server setting is set to the primary (principle
#    openvox-server/ca node)
#  * certificate extensions adds the role to the certificate to
#    simplify future lookup of role per infrastructure node
# 2. Hiera configuration is written for $cluster_id in the local
#    ./data/cluster dir
# 3. Each infrastructure node has the ov_role::${role} class applied
#    to it, with parameter data coming from the above hiera data
# 4. If there are any exclusively agent targets, they get their
#    puppet.conf server written to point to get_pool_address()
# 5. TODO: If $setup_infra_control_repo is true, add a static
#    ovox-control control repo on the primary to continue to enforce the
#    OpenVox configuration of infrastructure services
# 6. Validate agent runs on all nodes
# 7. Ensure agent service is set according to $agent_service_running
#    and $agent_service_enabled.
#
# @param cluster_id Unique String identifying the cluster of OpenVox
#   infrastructure being installed. Defines the local hiera data
#   hierarchy for the cluster under ./data/cluster/${cluster_id}.
# @param target_map The Ovox::TargetMap for the cluster.
# @param dns_alt_names Additional subject alternative names to be
#   added to the primary or compiler certs via puppet.conf.
# @param postgres_version Overwrite the PostgreSQL version to be
#   installed by the postgresql module.
# @param postgres_credentials TODO: credential hash for configuring
#   openvoxdb for a separate unmanaged PostgreSQL database
#   (somewhere).
# @param setup_infra_control_repo Whether to install an ovox-control
#   repo on the primary to manage infrastructure nodes post install.
# @param agent_service_running Final state of the OpenVox agent
#   service.
# @param agent_service_enabled Whether the OpenVox agent service will
#   be set as enabled (start on reboot).
# @param hiera_data_dir Without overwriting ./hiera.yaml, this must
#   be the module relative data/ directory. Generally this parameter
#   is only used internally in spec testing.
plan ovox::subplans::configure(
  String[1] $cluster_id,
  Ovox::TargetMap $target_map,
  Array[String[1]] $dns_alt_names = [],
  Optional[Ovox::Postgres_version] $postgres_version = undef,
  Hash $postgres_credentials = {},
  Boolean $setup_infra_control_repo = true,
  Boolean $agent_service_running = true,
  Boolean $agent_service_enabled = true,
  String[1] $hiera_data_dir = 'ovox/../data',
) {
  ##############################################
  # Setup targets and derive architecture roles.

  # TargetMap type has a singular primary_targets array.
  $primary = $target_map['primary_targets'][0]
  # Non-infrastructure agents
  $agent_targets = $target_map['agent_targets']
  $all_targets = ovox::all_agent_targets($target_map)
  $infrastructure_targets = $all_targets - $agent_targets
  $non_primary_infra = $infrastructure_targets - [$primary]

  $role_map = ovox::derive_role_map($target_map)

  # Store the role class of each infrastructure node.
  $infrastructure_targets.each() |$t| {
    set_var($t, 'role', ovox::get_role($t, $role_map))
  }

  ##################################################
  # Write local Hiera configuration for the cluster.
  $hiera_root = find_file($hiera_data_dir)
  $hiera_cluster_dir = "${hiera_root}/cluster/${cluster_id}"
  run_command("mkdir -p ${hiera_cluster_dir}/role", 'localhost')

  $hiera_layers = ovox::generate_hiera_layers(
    $target_map,
    $hiera_cluster_dir,
    {
      'postgres_version' => $postgres_version,
    }
  )

  # write local hiera configs
  # XXX: Needs to take into account re-runs that produce a different
  # set of layers...so if a map is empty, overwriting, and if there
  # are hiera layers left over from previous run that aren't being
  # touched, they should probably be removed. But it's important not
  # to remove anything in the cluster_id/custom layers...
  $hiera_layers.each() |$layer, $map| {
    if !$map.empty() {
      file::write($layer, stdlib::to_yaml($map))
    }
  }

  #########################################################
  # Configure puppet.conf and csr for infrastructure nodes.

  # TODO: dns_alt_names

  $infra_configure_results = run_task_with('openvox_bootstrap::configure',
    $infrastructure_targets
  ) |$target| {
    $task_params = {
      'puppet_conf' => {
        'main' => {
          'server' => $primary.name(),
        },
      },
      'csr_attributes' => {
        'extension_requests' => {
          'pp_role' => $target.vars['role'],
        }
      },
      'puppet_service_running' => false,
      'puppet_service_enabled' => $agent_service_enabled,
    }

    $task_params
  }
#  out::message($infra_configure_results)

  ###################################
  # Sign infrastructure certificates.

  if $non_primary_infra.length() > 0 {
    run_plan('ovox::subplans::certs',
      'primary' => $primary,
      'targets' => $non_primary_infra,
    )
  }

  #################################
  # Apply roles to nodes in stages.

  $apply_results = [
    # postgres should be up before openvoxdb since the later
    # needs the database configured before it can perform migrations
    $role_map['postgres'],
    # openvoxdb should be up before openvox-servers since the
    # classes for configuring server for ovdb perform a status check
    # on ovdb first
    $role_map['ovdb'] + $role_map['ovdb_lb'],
    # primary and compilers
    # (in a simple primary, the above relations are handled in the class itself)
    $role_map['primary'] + $role_map['compiler'] + $role_map['compiler_lb']
  ].map() |$targets| {
    apply($targets) {
      # The role var has been set in the Target.vars.
      include("ov_role::${role}")
    }
  }
#  out::message($apply_results)

  #########################
  # Setup non-infra agents.

  # We can now setup puppet.conf on any pure agent nodes to point to
  # the compilers.
  # compiler_pool_address or clb[0] or primary if no compilers...
  $agent_server = pick(ovox::get_pool_address('compiler', $target_map), $primary.name())
  $agent_configure_results = run_task('openvox_bootstrap::configure',
    $agent_targets,
    'puppet_conf' => {
      'main' => {
        'server' => $agent_server,
      },
    },
    'puppet_service_running' => false,
    'puppet_service_enabled' => $agent_service_enabled,
  )
#  out::message($agent_configure_results)

  # Sign agent certs
  if $agent_targets.length() > 0 {
    run_plan('ovox::subplans::certs',
      'primary' => $primary,
      'targets' => $agent_targets,
    )
  }

  ################################################
  # Setup primary ovox-control control repository.

  # TODO: setup control repo on the primary (this is separate from any
  # r10k configuration...or is a subset of r10k configuration)

  ##################
  # Final validation

  # Validate agent runs
  $agent_results = run_task('ovox::puppet_agent', $all_targets,
    'command' => 'run',
  )
#  out::message($agent_results)

  # Ensure agent service is started and enabled.
  $agent_service_results = run_task('openvox_bootstrap::configure',
    $all_targets,
    'puppet_service_running' => $agent_service_running,
    'puppet_service_enabled' => $agent_service_enabled,
  )
#  out::message($agent_service_results)
}
