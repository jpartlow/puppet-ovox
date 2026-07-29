require 'spec_helper'

describe 'ovox::has_small_primary' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  include_context('shared target maps')

  it 'is false for a tiny arch' do
    is_expected.to run.with_params(t_target_map).and_return(false)
  end

  it 'is true for a small arch' do
    is_expected.to run.with_params(s_target_map).and_return(true)
  end

  it 'is true for a medium arch' do
    is_expected.to run.with_params(m_target_map).and_return(true)
  end

  it 'is false for a large arch' do
    is_expected.to run.with_params(l_target_map).and_return(false)
  end

  it 'is false for a huge arch' do
    is_expected.to run.with_params(h_target_map).and_return(false)
  end

  it 'is false for a small arch with unmanaged postgres' do
    is_expected.to(
      run.with_params(unmanaged_postgres(s_target_map)).
        and_return(false)
    )
  end
end
