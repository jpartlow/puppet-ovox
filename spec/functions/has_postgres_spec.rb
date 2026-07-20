require 'spec_helper'

describe 'ovox::has_postgres' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  include_context('shared target maps')

  it 'is false for a tiny arch' do
    is_expected.to run.with_params(t_target_map).and_return(false)
  end

  it 'is true for other arch' do
    is_expected.to run.with_params(s_target_map).and_return(true)
    is_expected.to run.with_params(m_target_map).and_return(true)
    is_expected.to run.with_params(l_target_map).and_return(true)
    is_expected.to run.with_params(h_target_map).and_return(true)
  end

  context 'with external postgres' do
    it 'returns true' do
      is_expected.to(
        run.with_params(
          unmanaged_postgres(s_target_map)
        ).and_return(true)
      )
      is_expected.to(
        run.with_params(
          unmanaged_postgres(h_target_map)
        ).and_return(true)
      )
    end
  end
end
