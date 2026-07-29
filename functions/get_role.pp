# Return the exact role the given $target is assigned to based on the
# information in the given Ovox::RoleMap.
#
# Raises an error if the target maps to multiple roles.
#
# @param target The Target object to lookup in the role map.
# @param role_map The Ovox::RoleMap for the cluster the $target is
#   part of.
function ovox::get_role(
  Target $target,
  Ovox::RoleMap $role_map,
) >> Ovox::Roles {
  $roles = $role_map.filter |$entry| {
    $entry[1].any |$role_target| { $role_target == $target }
  }.keys()

  if $roles.length() > 1 {
    fail(@("EOS"))
      More than one role found for ${target}: ${roles}
      From role map: ${stdlib::to_json_pretty($role_map)}
      |- EOS
  }

  $roles[0]
}
