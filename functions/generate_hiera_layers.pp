# Return a Hash of hiera configuration based on an
# evaluation of the given $target_map and $base_config.
#
# The returned hash is keyed by the absolute path to the hiera file
# pointing to the hash of data to be written into the file by the
# caller.
#
# The function does not touch the file system itself.
#
# @param target_map Ovox::TargetMap instance for the cluster.
# @param hiera_cluster_dir The root directory for this cluster's hiera
#   data.
# @param base_config Hash of additional configuration data needed to
#   generate the hiera data.
function ovox::generate_hiera_layers(
  Ovox::TargetMap $target_map,
  Stdlib::AbsolutePath $hiera_cluster_dir,
  Hash $base_config,
) >> Hash[Stdlib::AbsolutePath,Hash] {
  $primary = $target_map['primary_targets'][0]

  $postgres_version = $base_config['postgres_version']
  $ca_server = ($primary =~ NotUndef) ? {
    true    => $primary.name(),
    default => undef,
  }

  $architecture = ovox::get_architecture($target_map)

  # generate profile flags for role specialization
  $profile_flags = ovox::derive_profile_flags($target_map)

  # Prep hiera configuration layers
  $common_config = {
    'puppet::client_package' => 'openvox-agent',
    'puppet::server_package' => 'openvox-server',
    'puppet::server_foreman' => false,
  }

  if ($architecture == 'ambiguous') or
     ($architecture == 'error') {
    $server_ovdb_config = {}
    $ovdb_config        = {}
    $postgres_config    = {}
    $compiler_config    = {}
  } else {
    $managed_postgres = !$target_map['postgres_targets'].empty()

    # XXX: Anything specific for the primary ca server?
    $ca_config = {}

    if $target_map['ovdb_targets'].empty() {
      $server_ovdb_config = {}
      $ovdb_config        = {}
    } else {
      $server_ovdb_config = {
        'puppet::server_reports'           => 'puppetdb',
        'puppet::server_storeconfigs'      => true,
        'puppet::server::puppetdb::server' =>
          ovox::get_ovdb_address($target_map),
      }
      $ovdb_base_config = {
        'openvoxdb::server::database_host' =>
          ovox::get_postgres_address($target_map),
      }
      $ovdb_credentials_config = $managed_postgres ? {
        true    => {
          'openvoxdb::server::postgresql::postgresql_ssl_on' => true,
        },
        default => {}
      }
      $ovdb_config = $ovdb_base_config + $ovdb_credentials_config
    }

    $postgres_config = $managed_postgres ? {
      true    => {
        'openvoxdb::database::postgresql::listen_address'    =>
          ovox::get_postgres_address($target_map),
        'openvoxdb::database::postgresql::postgres_version'  =>
          $postgres_version,
        'openvoxdb::database::postgresql::postgresql_ssl_on' => true,
        'openvoxdb::database::postgresql::puppetdb_server'   =>
          $target_map['ovdb_targets'][0].name(),
        # The puppet-openvoxdb module does not handle setting up
        # connection rules for more than one openvoxdb server, so the
        # extras are handed to the profile to manage.
        'ov_profile::postgres::additional_ovdb_servers' =>
          $target_map['ovdb_targets'][1,-1].map |$t| { $t.name() },
      }.filter() |$k, $v| { $v !~ Undef },
      default => {},
    }

    $compiler_config = ovox::has_compilers($target_map) ? {
      true    =>  {
        'puppet::ca_server' => $ca_server,
        'puppet::server_ca' => false,
      },
      default => {},
    }
  }

  $hiera_layers = {
    "${hiera_cluster_dir}/ovox.yaml" =>
      $profile_flags +
        $common_config +
        $server_ovdb_config +
        $ovdb_config +
        $postgres_config,
    "${hiera_cluster_dir}/role/compiler.yaml" =>
      $compiler_config,
  }

  $hiera_layers
}
