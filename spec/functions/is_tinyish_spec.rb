require 'spec_helper'

describe 'ovox::is_tinyish' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  include_context('shared target maps')

  it 'is true for a tiny arch' do
    is_expected.to run.with_params(t_target_map).and_return(true)
  end

  it 'is false for all other arch' do
    is_expected.to run.with_params(s_target_map).and_return(false)
    is_expected.to run.with_params(m_target_map).and_return(false)
    is_expected.to run.with_params(l_target_map).and_return(false)
    is_expected.to run.with_params(h_target_map).and_return(false)
  end

  it 'is false for a large arch with unmanaged postgres' do
    is_expected.to(
      run.with_params(unmanaged_postgres(l_target_map)).
        and_return(false)
    )
  end
end
