require 'spec_helper'

describe 'ovox::separate_postgres_targets' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  include_context('shared target maps')

  it 'returns an empty array for tiny, small and medium.' do
    is_expected.to run.with_params(t_target_map).and_return([])
    is_expected.to run.with_params(s_target_map).and_return([])
    is_expected.to run.with_params(m_target_map).and_return([])
  end

  it 'returns an array of postgres targets for large and huge' do
    is_expected.to(
      run.with_params(l_target_map).and_return( [ postgres ])
    )
    is_expected.to(
      run.with_params(h_target_map).and_return( [ postgres ])
    )
  end

  it 'returns an empty array for a custom with ovdb and postgres on the same non primary target' do
    l_target_map['ovdb_targets'] = [postgres]
    is_expected.to run.with_params(l_target_map).and_return([])
  end
end
