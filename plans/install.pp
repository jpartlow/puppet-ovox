# Coordinate openvox services installation and configuration on a set
# of provided hosts.
#
# @param primary_host The primary openvox-server host and certificate
#   authority.
# @param ovdb_hosts Array of openvoxdb hosts. By default, this is just
#   the $primary_host. If set to an empty array, no openvoxdb instance
#   will be installed in the cluster.
# @param postgres_hosts Array of PostgreSQL hosts for openvoxdb.
#   Defaults to the $primary_host. If set to an empty array, no
#   Postgresql hosts will be installed in the cluster.
#
#   NOTE: to use a separate postgres instance like a pre-configured
#   cloud instance, set postgres_hosts to the cloud instance so that
#   ovdbs are configured to talk to it, and set $manage_postgres to
#   false. See also $postgres_credentials.
# @param compiler_hosts Array of openvox-server compiler hosts.
# @param compiler_lb_hosts Array of haproxy load-balancers for the
#   compiler hosts.
# @param ovdb_lb_hosts Array of haproxy load-balancers for the ovdb
#   hosts.
# @param agent_hosts Array of additional agents to provision.
#   Note, the agent will also be installed on all of the above 
#   server, compiler, compiler lbs, ovdb lbs, ovdb and postgres hosts,
#   with the possible exception of $postgres_hosts if
#   $manage_postgres is false.
# @param openvox_collection String determining the over arching
#   version group for the openvox packages. If only openvox_collection
#   is set, then all installed openvox packages will be the latest
#   available from their respective package repositories within the
#   given collection.
# @param agent_ver_params Hash of version parameters for specifying
#   the specific package versions, either released or unreleased for
#   agent installation. See the Ovox::Openvox_install_params type for
#   details.
# @param server_ver_params Same as agent_ver_params, but for the
#   openvox-server package.
# @param compiler_ver_params Same as agent_ver_params, but for the
#   compiler openvox-server packages.
# @param ovdb_ver_params Same as agent_ver_params, but for the
#   openvoxdb package(s).
# @param install_defaults Provides defaults for each of the
#   *_ver_params hashes, allowing, minimally, just openvox_version to
#   be supplied.
# @param postgres_version The major or major.minor Postgresql version
#   string to be installed on $postgres_hosts. If not supplied, the
#   default version from the puppet-openvoxdb module will be used.
# @param install_termini Whether to install the openvoxdb-termini
#   package on server/compiler hosts so they can communicate with
#   openvoxdb instances.
# @param manage_postgres Whether to install and configure Postgresql
#   on the $postgres_hosts. Only set this false if $postgres_hosts is
#   pointing to a pre-configured Postgresql server (such as a cloud
#   instance) that will be handling database queries on behalf of the
#   cluster.
#
#   If instead the desired configuration is just a simple
#   $primary_host that only has openvox-server installed, set
#   $ovdb_hosts and $postgres_hosts to empty arrays.
# @param postgres_credentials Hash of credentials for connecting to a
#   pre-configured postgres host. For example, $postgres_hosts set to a
#   cloud instance, $manage_postgres set to false).
#   TODO: actual structure...
# @param compiler_pool_address If more than one $compiler_lb_hosts is
#   defined, this should be set to the general host address for reaching
#   the pool. The default is the first entry in $compiler_lb_hosts.
#
#   If $compiler_lb_hosts is empty but $compilers is not, then
#   $compiler_pool_address must be set to whatever external
#   load-balancing or dns multicast address solution is being used to
#   route traffic from agents to compilers.
# @param ovdb_pool_address Same as compiler_pool_address, but for the
#   $ovdb_hosts array. This is only relevant if there is more than one
#   entry in $ovdb_hosts.
# @param dns_alt_names Any additional hostnames to add to
#   openvox-server certificates. The compiler_pool_address will be added
#   automatically if it exists (set or calculated from
#   $compiler_lb_hosts).
plan ovox::install(
  # Hosts
  TargetSpec $primary_host,
  TargetSpec $ovdb_hosts        = $primary_host,
  TargetSpec $postgres_hosts    = $primary_host,
  TargetSpec $compiler_hosts    = [],
  TargetSpec $compiler_lb_hosts = [],
  TargetSpec $ovdb_lb_hosts     = [],
  TargetSpec $agent_hosts       = [],

  # Versions
  Ovox::Openvox_collection $openvox_collection = 'openvox8',
  Ovox::Openvox_install_params
    $agent_ver_params           = {},
  Ovox::Openvox_install_params
    $server_ver_params          = {},
  Ovox::Openvox_install_params
    $compiler_ver_params        = $server_ver_params,
  Ovox::Openvox_install_params
    $ovdb_ver_params            = $server_ver_params,
  Ovox::Openvox_install_params
    $install_defaults = {
      'openvox_version'       => 'latest',
      'openvox_collection'    => $openvox_collection,
      'openvox_released'      => true,
    },
  Optional[Ovox::Postgres_version] $postgres_version = undef,
  # TODO: ha_proxy version?

  # Configuration
  Boolean $install_termini                  = true,
  Boolean $manage_postgres                  = true,
  Optional[Hash] $postgres_credentials      = undef,
  Optional[String] $compiler_pool_address   = undef,
  Optional[String] $ovdb_pool_address       = undef,
  Optional[Array[String[1]]] $dns_alt_names = undef,
  # TODO: puppet-r10k parameters
  # TODO: CA parameters?
  # TODO: CSR parameters?
  # TODO: puppet.conf parameters?
  # TODO: agent service end state?
  # ???
) {

  $arch_map = run_plan('ovox::subplans::determine_architecture',
    'primary_host'          => $primary_host,
    'ovdb_hosts'            => $ovdb_hosts,
    'postgres_hosts'        => $postgres_hosts,
    'compiler_hosts'        => $compiler_hosts,
    'compiler_lb_hosts'     => $compiler_lb_hosts,
    'ovdb_lb_hosts'         => $ovdb_lb_hosts,
    'agent_hosts'           => $agent_hosts,
    'manage_postgres'       => $manage_postgres,
    'compiler_pool_address' => $compiler_pool_address,
    'ovdb_pool_address'     => $ovdb_pool_address,
  )

  # TODO: pre-checks?
  # * host os/openvox version compatiblity?
  # * existing postgres connection tests?
  # * server pre-reqs?
  # * openvox already installed? if so, need some skip flags to
  # allow re-running.

  # Install openvox packages
  run_plan('ovox::subplans::install_openvox',
    'openvox_agent_targets'    => $all_additional_agents,
    'openvox_server_targets'   => $server_targets,
    'openvox_compiler_targets' => $compiler_targets,
    'openvox_db_targets'       => $ovdb_targets,
    'openvox_agent_params'     => $agent_ver_params,
    'openvox_server_params'    => $server_ver_params,
    'openvox_compiler_params'  => $compiler_ver_params,
    'openvox_db_params'        => $server_ver_params,
    'install_defaults'         => $install_defaults,
    'install_termini'          => $install_termini,
  )

  # Configure openvox services/Install PostgreSQL
  run_plan('ovox::configure',
    'server_targets'       => $server_targets,
    'compiler_targets'     => $compiler_targets,
    'compiler_lb_targets'  => $compiler_lb_targets,
    'ovdb_targets'         => $ovdb_targets,
    'ovdb_lb_targets'      => $ovdb_lb_targets,
    'manage_postgres'      => $manage_postgres,
    'postgres_targets'     => $postgres_targets,
    'postgres_version'     => $postgres_version,
    'postgres_credentials' => $postgres_credentials,
    'postgres_host'        => $postgres_host,
    'agent_targets'        => $agent_targets,
    'dns_alt_names'        => $dns_alt_names,
  )

  # Post-tests?

  # Set agent service state?
}
