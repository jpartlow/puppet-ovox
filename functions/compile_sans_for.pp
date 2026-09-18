# Aggregate all of the dns_alt_name (subject alternative names) for
# the given role into a single array of strings without duplicates.
#
# By *role*, looks up and includes a pool address if any, any
# members of the appropriate load balancer class of targets (e.g.
# clb_compiler targets if the *role* is 'compiler'), and any
# sans found in *additional_sans_by_role*.
#
# Ensures that an array of strings is returned. May be empty.
#
# @param role
#   The architectural role to compile sans for.
# @param target_map
#   The Ovox::TargetMap for the cluster.
# @param additional_sans_by_role
#   Hash for additional sans to include keyed by role.
# @return
#   An array of SANs strings for the role.
function ovox::compile_sans_for(
  Ovox::Roles $role,
  Ovox::TargetMap $target_map,
  Ovox::SansMap $additional_sans_by_role = {},
) >> Array[String[1]] {
  $sans = [
    $target_map["${role}_pool_address"],
    $target_map["${role}_lb_targets"],
    $additional_sans_by_role[$role],
  ]

  $sans2 = $sans.reduce([]) |$ary,$e| {
    $stringified = case $e {
      String: {
        [$e]
      }
      Target: {
        [$t.name()]
      }
      Array[Target]: {
        $e.map |$t| { $t.name() }
      }
      default: { $e }
    }
    $ary + $stringified
  }.unique().filter() |$e| { $e =~ NotUndef }
}
