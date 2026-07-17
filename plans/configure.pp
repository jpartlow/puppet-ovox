plan ovox::configure(
    TargetSpec $server_targets,
    TargetSpec $compiler_targets = [],
    TargetSpec $compiler_lb_targets = [],
    TargetSpec $ovdb_targets = $server_targets,
    TargetSpec $postgres_targets = $server_targets,
    TargetSpec $agent_targets = [],
    Array[String[1]] $dns_alt_names = [],
    Optional[Ovox::Postgres_version] $postgres_version = undef,
    Hash $postgres_credentials = {},
) {

#  prep server ca
#  openvox_bootstrap::configure to set puppet.conf csr, but need an
#  arch function to determine roles
#  first puppet run to generate certs
}
