# Install OpenVox Puppet agents and primary services on the cluster
# without any attempts at configuration.
#
# The openvox_* install parameters are passed to tasks in the
# openvox_bootstrap module.
#
# Similarly to apply_prep, targets are marked with the puppet-agent
# feature, and facts are collected and added to the targets after
# agent installation.
#
# NOTE: The agent will be installed on server and db targets as well.
#
# NOTE: The openvoxdb-termini package will be installed on all server
# targets by default. Set $install_termini to false to skip this.
#
# @param target_map An Ovox::TargetMap for the cluster.
# @param openvox_agent_params The set of
#   Ovox::Openvox_install_params defining source
#   and version for the openvox-agent package to install on all
#   $targets.
# @param openvox_server_params The install params for the
#   openvox-server package to install on the $openvox_server_targets.
# @param openvox_db_params The install params for the
#   openvoxdb package to install on the $openvox_db_targets.
# @param install_defaults The default parameters to include
#   in each of the $openvox_*_params hashes.
# @param install_termini Whether to install the openvoxdb-termini
#   package on the $openvox_server_targets. The openvoxdb-termini
#   package contains Puppet terminus classes, functions and faces for
#   interacting with openvoxdb and is typically used to configure
#   openvox-server for communicating with openvoxdb.
# @param version_file_path Optional path to write an
#   openox_versions.<cluster_id>.json file containing the version map
#   of all installed OpenVox components. Useful for debugging in
#   automated pipelines. If undef (default), the file will not
#   be written.
plan ovox::subplans::install_openvox(
  Ovox::TargetMap $target_map,
  Ovox::Openvox_install_params
    $openvox_agent_params = {},
  Ovox::Openvox_install_params
    $openvox_server_params = {},
  Ovox::Openvox_install_params
    $openvox_compiler_params = {},
  Ovox::Openvox_install_params
    $openvox_db_params = {},
  Ovox::Openvox_install_params
    $install_defaults = {
      'openvox_version'       => 'latest',
      'openvox_collection'    => 'openvox8',
      'openvox_released'      => true,
    },
  Boolean $install_termini = true,
  Optional[String[1]] $version_file_path = undef,
) {
  # Resolve targets in case we were given hostname or inventory group
  # name references instead of Target objects.
  $agent_targets    = $target_map['agent_targets']
  $server_targets   = $target_map['server_targets']
  $compiler_targets = $target_map['compiler_targets']
  $all_server_targets = ($server_targets + $compiler_targets).unique()
  $ovdb_targets       = $target_map['ovdb_targets']
  $ovdb_termini_targets = $install_termini ? {
    true    => $all_server_targets,
    default => [],
  }
  $all_targets = ovox::all_agent_targets($target_map)

  $agent_version_results = run_plan(
    'ovox::subplans::install_component',
    'targets'  => $all_targets,
    'package'  => 'openvox-agent',
    'params'   => $openvox_agent_params,
    'defaults' => $install_defaults,
  )
  $agent_version_map = ovox::transform_openvox_host_version_results(
    'openvox-agent',
    $agent_version_results,
  )

  # Mark each target as having the puppet-agent.
  $all_targets.each |$target| {
    set_feature($target, 'puppet-agent', true)
  }

  # Collect facts and add them to the targets.
  run_plan('facts', 'targets' => $all_targets)

  $server_installations = [
    # XXX: There is a minor optimization that could be done here, if
    # $openvox_server_params == $openvox_compiler_params...
    [$server_targets, 'openvox-server', $openvox_server_params],
    [$compiler_targets, 'openvox-server', $openvox_compiler_params],
    [$ovdb_targets, 'openvoxdb', $openvox_db_params],
    [$ovdb_termini_targets, 'openvoxdb-termini', $openvox_db_params],
  ]
  $version_map = $server_installations.reduce($agent_version_map) |$map, $i| {
    $targets = $i[0]
    $package = $i[1]
    $params  = $i[2]

    if $targets.empty() { next($map) }

    $version_results = run_plan(
      'ovox::subplans::install_component',
      'targets'  => $targets,
      'package'  => $package,
      'params'   => $params,
      'defaults' => $install_defaults,
    )

    ovox::transform_openvox_host_version_results(
      $package,
      $version_results,
      $map,
    )
  }

  if $version_file_path =~ NotUndef {
    $cluster_id = $all_targets[0].vars['cluster_id']
    file::write("${version_file_path}/openvox_versions.${cluster_id}.json",
      stdlib::to_json_pretty($version_map),
    )
  }

  return($version_map)
}
