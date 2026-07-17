# Given a $role that is in a $role_map Hash of $role => $targets,
# produce an array of error messages if any $role targets are present
# in any other targets in the $role_map.
#
# @param role The role entry to test.
# @param role_map A Hash keyed by role strings pointing to arrays of
#   Targets, including the entry for $role itself.
# @return An array of error messages for any detected role target
#   intersections.
function ovox::check_role_target_intersection(
  String $role,
  Hash[String,Array[Target]] $role_map,
) >> Array[String] {
  if ! ($role in $role_map) {
    fail("ovox::check_role_target_intersection: Role '${role}' not found in the given role_map hash (keys: ${role_map.keys()})")
  }
  $role_targets = $role_map[$role]
  $others = $role_map.filter |$r, $_targets| { $r != $role }
  $others.reduce([]) |$errors, $pair|  {
    $other_role = $pair[0]
    $other_targets = $pair[1]
    $conflicts = intersection($role_targets, $other_targets)
    if !$conflicts.empty() {
      $err = "The ${role} hostnames should be unique, but were found in the ${other_role} list: ${conflicts}"
      $errors + [$err]
    } else {
      $errors
    }
  }
}
