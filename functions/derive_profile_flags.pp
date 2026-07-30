# Return a map of profile flags based on cluster TargetMap.
#
# Intended to populate hiera data to inform key primary and ovdb roles
# as to which profiles to include for this cluster.
#
# This only addresses the simple case of uniform role classification
# across the cluster. In the case of the primary, the module only
# supports one node. In the case of ovdb nodes that are not the
# primary, this assumes they all either have or do not have postgres. 
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::derive_profile_flags(
  Ovox::TargetMap $target_map,
) >> Hash[String,Boolean] {
  $primary_flags = {
    'ov_role::primary::install_ovdb' =>
      ovox::role_includes('primary', 'ovdb', $target_map),
    'ov_role::primary::install_postgres' =>
      ovox::role_includes('primary', 'postgres', $target_map),
  }

  $ovdb_flags = ovox::has_separate_ovdbs($target_map) ? {
    true => {
      'ov_role::ovdb::install_postgres' => 
        ovox::role_includes('ovdb', 'postgres', $target_map)
    },
    default => {},
  }

  $primary_flags + $ovdb_flags
}
