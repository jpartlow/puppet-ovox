require 'spec_helper'

describe 'ovox::has_separate_ovdbs' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  include_context('shared target maps')

  it 'is true for huge arch' do
    is_expected.to run.with_params(h_target_map).and_return(true)
  end

  it 'is false otherwise' do
    is_expected.to run.with_params(t_target_map).and_return(false)
    is_expected.to run.with_params(s_target_map).and_return(false)
    is_expected.to run.with_params(m_target_map).and_return(false)
    is_expected.to run.with_params(l_target_map).and_return(false)
  end
end
