# Generate a Hash of hiera configuration based on an
# evaluation of the given $target_map and $base_config.
#
# The returned hash is keyed by the absolute path to the hiera file
# pointing to the hash of data to be written into the file by the
# caller.
#
# The function does not touch the file system itself.
#
# @param target_map
#   Ovox::TargetMap instance for the cluster.
# @param hiera_cluster_dir
#   The root directory for this cluster's hiera data.
# @param base_config
#   Hash of additional configuration data needed to generate the hiera
#   data.
#
#   * `postgres_version` - The version of Postgresql to install on
#   postgres nodes.
#   * `additional_sans_map` - Hash of additional SANs for Puppet
#   dns_alt_names setting keyed by role.
# @return
#   A Hash of hiera data hashes keyed by file path.
function ovox::generate_hiera_layers(
  Ovox::TargetMap $target_map,
  Stdlib::AbsolutePath $hiera_cluster_dir,
  Struct[{
    Optional[postgres_version]    => Optional[Ovox::Postgres_version],
    Optional[additional_sans_map] => Ovox::SansMap,
  }] $base_config,
) >> Hash[Stdlib::AbsolutePath,Hash] {
  $primary = $target_map['primary_targets'][0]

  $postgres_version = $base_config['postgres_version']
  $additional_sans_map = pick($base_config['additional_sans_map'], {})

  $ca_server = ($primary =~ NotUndef) ? {
    true    => $primary.name(),
    default => undef,
  }

  $architecture = ovox::get_architecture($target_map)

  # generate profile flags for role specialization
  $profile_flags = ovox::derive_profile_flags($target_map)

  # Prep hiera configuration layers
  $common_config = {
    # For the moment, prevent agents managed by the puppet module
    # from ending up with the 'bolt_catalog' environment...
    'puppet::agent_manage_environment' => false,
    # Ensure puppet module sets the primary as the puppetserver
    # for infrastructure agents.
    'puppet::agent_server_hostname'    => $ca_server,
    'puppet::client_package'           => 'openvox-agent',
    'puppet::server_package'           => 'openvox-server',
    'puppet::server_foreman'           => false,
  }

  if ($architecture == 'ambiguous') or
     ($architecture == 'error') {
    $server_config        = {}
    $server_ovdb_config   = {}
    $ovdb_config          = {}
    $postgres_config      = {}
    $compiler_role_config = {}
    $ovdb_role_config     = {}
    $lb_configs           = {
      'compiler' => {},
      'ovdb'     => {},
    }
  } else {
    $managed_postgres = !$target_map['postgres_targets'].empty()

    # XXX: Anything specific for the primary ca server?
    $ca_config = {}

    $server_config = !$target_map['primary_targets'].empty() ? {
      true => {
        'puppet::server'                => true,
        # Do not setup for foreman ENC...must be an empty string
        # rather than undef to be picked by Hiera automatic parameter
        # lookup.
        'puppet::server_external_nodes' => '',
      },
      default => {},
    }

    if $target_map['ovdb_targets'].empty() {
      $server_ovdb_config = {}
      $ovdb_config        = {}
    } else {
      $server_ovdb_config = {
        'puppet::server_reports'           => 'puppetdb',
        'puppet::server_storeconfigs'      => true,
        # (2026-08-25) Not using puppet::server::puppetdb because it
        # currently wraps puppetdb::master::config and we're using the
        # openvoxdb module instead...
        'openvoxdb::master::config::puppetdb_server'     =>
          ovox::get_ovdb_address($target_map),
        # Also, these are false because theforeman-puppet is managing
        # them...
        'openvoxdb::master::config::manage_storeconfigs' => false,
        'openvoxdb::master::config::restart_puppet'      => false,
        # This uses an openvoxdb type/provider puppetdb_conn_validation
        # which uses ssl and trips over the bolt puppet environment
        # not having the ca cert.
        'openvoxdb::master::config::strict_validation'   => false,
      }
      $ovdb_base_config = {
        'openvoxdb::server::database_host' =>
          ovox::get_postgres_address($target_map),
      }
      $ovdb_credentials_config = $managed_postgres ? {
        true    => {
          'openvoxdb::server::postgresql_ssl_on' => true,
        },
        default => {}
      }
      $ovdb_config = $ovdb_base_config + $ovdb_credentials_config
    }

    $postgres_config = $managed_postgres ? {
      true    => {
        'openvoxdb::database::postgresql::listen_addresses'    =>
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

    $ovdb_sans = ovox::compile_sans_for(
      'ovdb',
      $target_map,
      $additional_sans_map,
    )
    $ovdb_role_config = $ovdb_sans.empty() ? {
      false   => {
        'puppet::dns_alt_names' => $ovdb_sans,
      },
      default => {},
    }

    $compiler_role_config = ovox::has_compilers($target_map) ? {
      true    =>  {
        'puppet::ca_server'     => $ca_server,
        'puppet::server'        => true,
        'puppet::server_ca'     => false,
        'puppet::dns_alt_names' => ovox::compile_sans_for(
          'compiler',
          $target_map,
          $additional_sans_map,
        ),
      },
      default => {},
    }

    $lb_configs = [
      'compiler',
      'ovdb',
    ].reduce({}) |$config,$role| {
      $has_lbs = !$target_map["${role}_lb_targets"].empty()
      $lb_members = $target_map["${role}_targets"]
      $lb_config = $has_lbs ? {
        true    => {
          'ov_profile::lb::members' => $lb_members.reduce({}) |$ac,$m| {
            $ac + { $m.name() => $m.facts()['networking']['ip'] }
          }
        },
        default => {},
      }
      $config + { $role => $lb_config }
    }
  }

  $hiera_layers = {
    "${hiera_cluster_dir}/ovox.yaml" =>
      $profile_flags +
        $common_config +
        $server_config +
        $server_ovdb_config +
        $ovdb_config +
        $postgres_config,
    "${hiera_cluster_dir}/role/compiler.yaml" =>
      $compiler_role_config,
    "${hiera_cluster_dir}/role/ovdb.yaml" =>
      $ovdb_role_config,
    "${hiera_cluster_dir}/role/compiler_lb.yaml" =>
      $lb_configs['compiler'],
    "${hiera_cluster_dir}/role/ovdb_lb.yaml" =>
      $lb_configs['ovdb'],
  }

  $hiera_layers
}
