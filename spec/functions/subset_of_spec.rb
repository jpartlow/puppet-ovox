require 'spec_helper'

describe 'ovox::subset_of' do
  it 'is true if array is contained by other' do
    is_expected.to run.with_params([2,1], [1,2,3]).and_return(true)
    is_expected.to run.with_params([1,2], [1,2,3]).and_return(true)
  end

  it 'is true if array has the same elements as other' do
    is_expected.to run.with_params([2,1], [1,2]).and_return(true)
    is_expected.to run.with_params([1,2], [1,2]).and_return(true)
  end

  it 'is false if array only has some of the same elements as other' do
    is_expected.to run.with_params([2,3], [2,1,4]).and_return(false)
  end

  it 'is false if array is disjoint from other' do
    is_expected.to run.with_params([2,3], [1,4]).and_return(false)
  end
end
