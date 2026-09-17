# Configure all services for the cluster.
#
# Also involves installation of services such as PostgreSQL, HAProxy
# and such.
#
# This plan basically runs through the following phases:
#
# 1. Targets are formally assigned a role
# 2. Hiera configuration is written for $cluster_id in the local
#    ./data/cluster dir
# 3. Configure puppet.conf and csr_attributes.yaml on infrastructure
#    nodes.
#  * puppet server setting is set to the primary (principle
#    openvox-server/ca node)
#  * certificate extensions adds the role to the certificate to
#    simplify future lookup of role per infrastructure node
# 4. Generate and sign infrastructure certificates
# 5. Each infrastructure node has the ov_role::${role} class applied
#    to it, with parameter data coming from the above hiera data
# 6. If there are any exclusively agent targets, they get their
#    puppet.conf server written to point to get_pool_address(),
#    and set their caserver to the primary
# 7. Generate and sign agent certificates, if any
# 8. TODO: If $setup_infra_control_repo is true, add a static
#    ovox-control control repo on the primary to continue to enforce the
#    OpenVox configuration of infrastructure services
# 9. Validate agent runs on all nodes
#    NOTE: purely for validation purposes, in medium, large and huge
#    clusters that have compilers, an agent node is useful to validate
#    that agents can successfully obtained catalogs from the
#    compilers. All infrastructure catalogs come from the primary.
# 10. Ensure agent service is set according to $agent_service_running
#     and $agent_service_enabled.
#
# @param cluster_id Unique String identifying the cluster of OpenVox
#   infrastructure being installed. Defines the local hiera data
#   hierarchy for the cluster under ./data/cluster/${cluster_id}.
# @param target_map The Ovox::TargetMap for the cluster.
# @param compiler_dns_alt_names Any additional hostnames to add to
#   openvox-server certificates. The compiler_pool_address will be added
#   automatically if it exists (set or calculated from
#   $compiler_lb_hosts).
# @param ovdb_dns_alt_names Any additional hostnames to add to
#   openvoxdb certificates. The ovdb_pool_address will be added
#   automatically if it exists (set or calculated from
#   $ovdb_lb_hosts).
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
# @param capture_apply_reports If set to true, writes apply result
#   output to a module local ./reports director during the configure
#   stage so the reports can be reviewed for debugging. Files are
#   separated by cluster_id and timestamp.
plan ovox::subplans::configure(
  String[1] $cluster_id,
  Ovox::TargetMap $target_map,
  Array[String[1]] $compiler_dns_alt_names = [],
  Array[String[1]] $ovdb_dns_alt_names = [],
  Optional[Ovox::Postgres_version] $postgres_version = undef,
  Hash $postgres_credentials = {},
  Boolean $setup_infra_control_repo = true,
  Boolean $agent_service_running = true,
  Boolean $agent_service_enabled = true,
  String[1] $hiera_data_dir = 'ovox/../data',
  Boolean $capture_apply_reports = false,
  String[1] $reports_dir = 'ovox/../reports',
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
  $additional_sans_map = {
    'compiler' => $compiler_dns_alt_names,
    'ovdb'     => $ovdb_dns_alt_names,
  }

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
      'postgres_version'    => $postgres_version,
      'additional_sans_map' => $additional_sans_map,
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

  $infra_configure_results = run_task_with('openvox_bootstrap::configure',
    $infrastructure_targets
  ) |$target| {
    $role = $target.vars['role']
    $dns_alt_names = ovox::compile_sans_for(
      $role,
      $target_map,
      $additional_sans_map,
    )
    $sans_parameter = $dns_alt_names.empty() ? {
      false   => {
        'dns_alt_names' => $dns_alt_names.join(','),
      },
      default => {},
    }
    $main = {
      'server' => $primary.name(),
    } + $sans_parameter

    $task_params = {
      # NOTE: This is not redundant with the later theforeman-puppet
      # apply managing puppet.conf, because the ovox::subplans::cert
      # invocations of puppet ssl also need the server set...
      'puppet_conf' => {
        'main' => $main,
      },
      'csr_attributes' => {
        'extension_requests' => {
          'pp_role' => $role,
        }
      },
      'puppet_service_running' => false,
      'puppet_service_enabled' => $agent_service_enabled,
    }

    $task_params
  }
#  out::message($infra_configure_results)

  ################################################
  # Configure puppetserver for certificate signing

  # Ensure allow-subject-alt-names is true for cert generation.
  # This temporary ca.conf will be overwritten by puppet-puppet
  # during the later apply stage.
  upload_file(
    'ovox/puppetserver/conf.d/ca.conf.bootstrap',
    '/etc/puppetlabs/puppetserver/conf.d/ca.conf',
    $primary,
  )

  ###################################
  # Sign infrastructure certificates.

  run_plan('ovox::subplans::certs',
    'primary'      => $primary,
    'targets'      => $non_primary_infra,
    'ovdb_targets' => $target_map['ovdb_targets'],
  )

  #################################
  # Apply roles to nodes in stages.

  $first_ovdb_node =
    (Array($role_map['ovdb'][0], true)).filter |$i| { $i =~ NotUndef }
  $rest_of_ovdb_nodes = (
      Array($role_map['ovdb'][1,-1], true)
  ).filter |$i| { $i =~ NotUndef }

  $apply_results = [
    # postgres
    #
    # postgres should be up before openvoxdb since the later
    # needs the database configured before it can perform migrations
    $role_map['postgres'],
    # openvoxdb
    #
    # openvoxdb should be up before openvox-servers since the
    # classes for configuring server for ovdb perform a status check
    # on ovdb first
    #
    # Additionally, however, when we have multiple openvoxdb nodes (in
    # a huge architecture, for example), there is a race by the
    # openvoxdb instances to populate postgres with their schema.
    # The process is well-behaved in the sense that only one succeeds,
    # and the database is initialized properly, but if run in
    # parallel, the loosing ovdb nodes will tend to fail their initial
    # startup as postgres will return an error for attempts to enter
    # duplicate schema rows. They will succeed in subsequent runs.
    #
    # To avoid this, apply the first ovdb node separately.
    $first_ovdb_node,
    # Then apply the rest of them...and everything should still
    # configure in one plan execution.
    $rest_of_ovdb_nodes + $role_map['ovdb_lb'],
    # Note: in a simple primary, the above relations are handled in
    # the class itself
    #
    # primary and compilers
    $role_map['primary'] + $role_map['compiler'] + $role_map['compiler_lb']
  ].map() |$targets| {
    if !$targets.empty() {
      $apply_resultset = apply($targets, '_catch_errors' => true) {
        # The role var has been set in the Target.vars.
        include("ov_role::${role}")
      }

      if $capture_apply_reports {
        $reports_root = find_file($reports_dir)
        $now = Timestamp()
        $ts_str = $now.strftime('%Y-%m-%dT%H.%M.%S.%L')
        $cluster_reports = "${reports_dir}/${cluster_id}/${ts_str}"
        out::message("Saving apply results to: ${cluster_reports}")
        run_command("mkdir -p '${cluster_reports}'", 'localhost')
        $apply_resultset.results().each |$ar| {
          $target = $ar.target()
          $target_dir = "${cluster_reports}/${target}"
          run_command("mkdir '${target_dir}'", 'localhost')
          file::write(
            "${target_dir}/apply-result.${target}.json",
            stdlib::to_json_pretty($ar.to_data())
          )
          $report = $ar.report()
          if $report =~ NotUndef {
            file::write(
              "${target_dir}/report.${target}.json",
              stdlib::to_json_pretty($report)
            )
          }
          $catalog = $ar.catalog()
          if $catalog =~ NotUndef {
            file::write(
              "${target_dir}/catalog.${target}.json",
              stdlib::to_json_pretty($report)
            )
          }
          $error = $ar.error()
          if $error =~ NotUndef {
            file::write(
              "${target_dir}/error.${target}.json",
              stdlib::to_json_pretty(
                {
                  'message' => $error.message,
                  'kind'    => $error.kind,
                  'details' => $error.details,
                }
              )
            )
          }
          file::write(
            "${target_dir}/message.${target}",
            "$ar.message()\n"
          )
        }
      }

      if !$apply_resultset.ok() {
        out::message("Successful catalog runs:")
        $apply_resultset.ok_set().each |$ar| {
          $t = $ar.target()
          $role = $t.vars()['role']
          out::message("\nReport for successful ${role} role ${t}:\n")
          ovox::log_apply_report($ar)
          out::message("\n---")
        }
        out::message("Failed catalog runs:")
        $apply_resultset.error_set().each |$ar| {
          $t = $ar.target()
          $role = $t.vars()['role']
          out::message("\nReport for failed ${role} role ${t}:\n")
          ovox::log_apply_report($ar)
          out::message("\nFailure for ${t}: ${ar.error()}")
          out::message("\n---")
        }
        fail_plan($apply_resultset.error_set()[0].error())
      }

      $apply_resultset
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
        'server'    => $agent_server,
        # openvox-server doesn't have a built in reverse proxy
        # allowing compilers to proxy puppet-ca requests, so the basic
        # solution is to have agents target the primary directly for
        # ca requests.
        'ca_server' => $primary.name(),
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

  ##############################################
  # Ensure agent service is started and enabled.
  $agent_service_results = run_task('openvox_bootstrap::configure',
    $all_targets,
    'puppet_service_running' => $agent_service_running,
    'puppet_service_enabled' => $agent_service_enabled,
  )
#  out::message($agent_service_results)
}
