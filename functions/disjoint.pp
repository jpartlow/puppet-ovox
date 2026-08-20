# True if there is no intersection of elements between the given
# arrays.
#
# @param first The first array.
# @param second The second array.
function ovox::disjoint(
  Array $first,
  Array $second,
) >> Boolean {
  intersection($first, $second).empty()
}
