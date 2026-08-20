# Given a TargetMap, perform some hueristics and return the
# appropriate architecture label from Ovox::Architectures.
#
# see docs/architectures.md for a description of the named architectures.
# see types/architectures.pp for notes on 'custom', 'ambiguous' and
# 'error' values.
#
# @param target_map Ovox::TargetMap instance for the cluster.
function ovox::get_architecture(
  Ovox::TargetMap $target_map,
) >> Ovox::Architectures {
  $info = ovox::validate_architecture($target_map)
  if !$info['errors'].empty() {
    $architecture = 'error'
  } elsif !$info['ambiguities'].empty() {
    $architecture = 'ambiguous'
  } elsif (
    ovox::is_tinyish($target_map) and
    ! ovox::has_compilers($target_map)
  ) {
     $architecture = 'tiny'
  } elsif (
    ovox::is_smallish($target_map) and
    ! ovox::has_compilers($target_map)
  ) {
     $architecture = 'small'
  } elsif (
    ovox::is_smallish($target_map) and
    ovox::has_compilers($target_map)
  ) {
     $architecture = 'medium'
  } elsif (
    ovox::is_largish($target_map) and
    ovox::has_compilers($target_map)
  ) {
     $architecture = 'large'
  } elsif (
    ovox::is_hugish($target_map) and
    ovox::has_compilers($target_map)
  ) {
     $architecture = 'huge'
  } else {
     $architecture = 'custom'
  }
  $architecture
}
