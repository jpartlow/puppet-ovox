# Determine if given arrays are disjoint.
#
# @param first The first array.
# @param second The second array.
# @return
#   True if there is no intersection of elements between the given
#   arrays.
function ovox::disjoint(
  Array $first,
  Array $second,
) >> Boolean {
  intersection($first, $second).empty()
}
