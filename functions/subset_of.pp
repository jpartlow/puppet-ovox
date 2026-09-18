# Test whether the first array's elements are a subset of the second
# array.
#
# @param candidate
#   The array we are testing.
# @param collection
#   Proposed superset of the candidate array.
# @return
#   True if *candidate*'s elements are all contained within the
#   *collection*.
function ovox::subset_of(
  Array $candidate,
  Array $collection,
) >> Boolean {
  $candidate == intersection($candidate, $collection)
}
