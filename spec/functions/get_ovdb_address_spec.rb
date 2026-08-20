require 'spec_helper'

describe 'ovox::get_ovdb_address' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  include_context('shared target maps')

  it 'returns the primary in small cluster' do
    is_expected.to(
      run.with_params(s_target_map).and_return('primary.spec')
    )
  end

  it 'returns undef when no openvoxdb server is defined' do
    is_expected.to(
      run.with_params(t_target_map).and_return(nil)
    )
  end

  it 'returns the load balancer when multiple ovdb defined' do
    is_expected.to(
      run.with_params(h_target_map).and_return('ovdblb.spec')
    )
  end

  it 'returns the ovdb server when a separate ovdb server is defined' do
    s_target_map['ovdb_targets'] = [ovdb1]
    is_expected.to(
      run.with_params(s_target_map).and_return('ovdb1.spec')
    )
  end
end
