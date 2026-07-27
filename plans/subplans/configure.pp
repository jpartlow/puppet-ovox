plan ovox::configure(
    Ovox::TargetMap $target_map,
    Array[String[1]] $dns_alt_names = [],
    Optional[Ovox::Postgres_version] $postgres_version = undef,
    Hash $postgres_credentials = {},
) {

  # prep server ca
  # openvox_bootstrap::configure to set puppet.conf csr, but need an
  # arch function to determine roles
  # first puppet run to generate certs
}
