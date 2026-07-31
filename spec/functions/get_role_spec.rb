require 'spec_helper'

describe 'ovox::get_role' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  include_context('shared target maps')

  let(:role_map) do
    {
      'primary'     => [primary],
      'ovdb'        => [postgres],
      'postgres'    => [postgres],
      'compiler'    => [compiler1],
      'compiler_lb' => [],
      'ovdb_lb'     => [],
    }
  end

  it 'returns the matching role for a target' do
    is_expected.to(
      run.with_params(compiler1, role_map).
        and_return('compiler')
    )
  end

  it 'raises an error if no role is found' do
    is_expected.to(
      run.with_params(clb, role_map).
        and_raise_error(/No role found/)
    )
  end

  it 'raises an error if more than one role is found' do
    is_expected.to(
      run.with_params(postgres, role_map).
        and_raise_error(%r{More than one role found})
    )
  end
end
