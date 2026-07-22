require 'spec_helper'

describe 'ovox::separate_ovdb_targets' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  include_context('shared target maps')

  it 'returns an empty array for tiny, small, medium and large.' do
    is_expected.to run.with_params(t_target_map).and_return([])
    is_expected.to run.with_params(s_target_map).and_return([])
    is_expected.to run.with_params(m_target_map).and_return([])
    is_expected.to run.with_params(l_target_map).and_return([])
  end

  it 'is returns an array of the ovdb targets in huge' do
    is_expected.to(
      run.with_params(h_target_map).and_return(
        [
          ovdb1,
          ovdb2,
        ]
      )
    )
  end
end
