# Return a RoleMap linking the ov_role classes to the
# array of targets they will be applied to in the cluster.
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::derive_role_map(
  Ovox::TargetMap $target_map,
) >> Ovox::RoleMap {
  $role_map = {
    'primary'     => $target_map['server_targets'],
    'ovdb'        => ovox::separate_ovdb_targets($target_map),
    'postgres'    => ovox::separate_postgres_targets($target_map),
    'compiler'    => $target_map['compiler_targets'],
    'compiler_lb' => $target_map['compiler_lb_targets'],
    'ovdb_lb'     => $target_map['ovdb_lb_targets'],
  }

  $role_map
}
