# All nodes that need to be earmarked for agent installation so that
# we can later manage them with OpenVox.
#
# @param target_map The TargetMap for the cluster.
function ovox::all_agent_targets(
  Ovox::TargetMap $target_map,
) >> Array[Target] {
  [
    $target_map['server_targets'],
    $target_map['ovdb_targets'],
    $target_map['compiler_targets'],
    $target_map['agent_targets'],
    $target_map['postgres_targets'],
    $target_map['compiler_lb_targets'],
    $target_map['ovdb_lb_targets'],
  ].flatten().unique()
}
