require 'spec_helper'

describe 'ovox::disjoint' do
  it 'is true if arrays contain nothing in common' do
    is_expected.to run.with_params([1, 2], [3, 4]).and_return(true)
  end

  it 'is false if arrays are equal' do
    is_expected.to run.with_params([1, 2], [1, 2]).and_return(false)
  end

  it 'is false if a is a subset of b' do
    is_expected.to run.with_params([1, 2], [1, 2, 3]).and_return(false)
  end

  it 'is false if b is a subset of a' do
    is_expected.to run.with_params([1, 2, 3], [1]).and_return(false)
  end

  it 'is false if a and b contain any common elements' do
    is_expected.to run.with_params([2, 3], [1, 2]).and_return(false)
  end
end
