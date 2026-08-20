# Return the hostname of the Openvoxdb server that Openvox-servers
# should be configured to communicate with.
#
# If there is a single configured openvoxdb server in the cluster,
# that address will be returned. If there are multiple openvoxdb
# servers in the cluster, then the result of ovox::get_pool_address()
# will be returned.
#
# Otherwise the function returns undef.
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::get_ovdb_address(
  Ovox::TargetMap $target_map,
) >> Optional[String] {
  $ovdb_targets = $target_map['ovdb_targets']
  case $ovdb_targets.length() {
    0: { undef }
    1: { $ovdb_targets[0].name() }
    default: { ovox::get_pool_address('ovdb', $target_map) }
  }
}
