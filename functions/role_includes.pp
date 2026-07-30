# Tests whether all targets of the given $role are also targets of the
# $included_role.
#
# Example:
#
#   role_includes('primary', 'ovdb')
#
# This will return true if all primary targets will also have
# openvoxdb installed and configured on them.
#
# @param role Role key for the set of targets in the cluster to test.
# @param included_role Role key for the set of targets $role may also
#   include.
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::role_includes(
  Ovox::Roles $role,
  Ovox::Roles $included_role,
  Ovox::TargetMap $target_map,
) >> Boolean {
  $role_targets = $target_map["${role}_targets"]
  $included_targets = $target_map["${included_role}_targets"]

  ovox::subset_of($role_targets, $included_targets)
}
