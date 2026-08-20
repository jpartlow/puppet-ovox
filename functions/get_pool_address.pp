# Return the hostname for the requested load-balancer pool.
#
# This will either be the String given to the install plan for the
# respective pool_address field, or the hostname of the first
# load-balancer target in the TargetMap for the given pool.
#
# May return `undef` if neither is defined.
#
# @param pool Either 'compiler' or 'ovdb'.
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::get_pool_address(
  Ovox::LbPools $pool,
  Ovox::TargetMap $target_map,
) >> Optional[String] {
  $lb_targets      = $target_map["${pool}_lb_targets"]
  $lb_pool_address = $target_map["${pool}_pool_address"]

  if $lb_pool_address =~ Undef {
    $pool_address = $lb_targets.empty() ? {
      false   => $lb_targets[0].name(),
      default => undef,
    }
  } else {
    $pool_address = $lb_pool_address
  }

  $pool_address
}
