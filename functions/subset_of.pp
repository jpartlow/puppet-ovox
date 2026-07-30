# True if first array's elements are all contained within the second
# array.
#
# @param candidate The array we are testing.
# @param collection Proposed superset of the candidate array.
function ovox::subset_of(
  Array $candidate,
  Array $collection,
) >> Boolean {
  $candidate == intersection($candidate, $collection)
}
