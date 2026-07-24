# All nodes that need to be earmarked for agent installation so that
# we can later manage them with OpenVox. The openvox nodes (server,
# ovdb, compiler) all get agents installed prior to their service
# packages being installed as a matter of course, so are not included
# in this list.
#
# @param target_map The TargetMap for the cluster.
function ovox::all_agent_targets(
  Ovox::TargetMap $target_map,
) >> Array[Target] {
  [
    $target_map['agent_targets'],
    $target_map['compiler_lb_targets'],
    $target_map['ovdb_lb_targets'],
    ovox::separate_postgres_targets($target_map),
  ].flatten().unique()
}
