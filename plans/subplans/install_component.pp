# Installs a single openvox component on behalf of the caller.
#
# Uses puppet-openvox_bootstrap tasks.
#
# @param targets The targets to install the component on.
# @param package The name of the package to install.
# @param params The parameters for the openvox installation.
# @param defaults The default parameters for the openvox installation.
plan ovox::subplans::install_component(
  TargetSpec $targets,
  String $package,
  Ovox::Openvox_install_params $params,
  Ovox::Openvox_install_params $defaults,
) {
  $install_params = ovox::validate_openvox_version_parameters(
    $defaults + $params,
  )

  $released = $install_params['openvox_released']
  $version = $install_params['openvox_version']
  $collection = $install_params['openvox_collection']

  out::message("Installing ${package} ${version} (${collection})")

  if $released {
    $force_release_package = $install_params['force_release_package']
    $final_install_params = $force_release_package =~ NotUndef ? {
      true    => {
        'force_release_package' =>  $force_release_package,
      },
      default => {},
    } + {
      'package'       => $package,
      'version'       => $version,
      'collection'    => $collection,
      '_catch_errors' => true,
    }
    # Loop in case of package manager locks from another process.
    $installed = ctrl::do_until(limit => 5, interval => 10) || {
      $install_results = run_task(
        'openvox_bootstrap::install',
        $targets,
        $final_install_params,
      )
      ovox::test_results("Error installing ${package}", $install_results)
    }
  } else {
    $artifacts_url = $install_params['openvox_artifacts_url']
    $install_build_params = $artifacts_url =~ NotUndef ? {
      true    => {
        'artifacts_source' => $artifacts_url,
      },
      default => {},
    } + {
      'package'      => $package,
      'version'      => $version,
      '_catch_errors' => true,
    }
    # Loop in case of package manager locks from another process.
    $installed = ctrl::do_until(limit => 5, interval => 10) || {
      $install_results = run_task(
        'openvox_bootstrap::install_build_artifact',
        $targets,
        $install_build_params,
      )
      ovox::test_results("Error installing ${package}", $install_results)
    }
  }

  if !$installed {
    fail("Failed to install ${package} on some targets (see above).")
  }

  $version_results = run_task('package', $targets, {
    'name'    => $package,
    'action'  => 'status',
  })

  return $version_results
}
