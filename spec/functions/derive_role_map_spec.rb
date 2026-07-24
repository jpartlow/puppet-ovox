require 'spec_helper'

describe 'ovox::derive_role_map' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  include_context('shared target maps')

  it 'generates a role_map for tiny' do
    is_expected.to run.with_params(t_target_map).and_return(
      {
        'primary'     => [primary],
        'ovdb'        => [],
        'postgres'    => [],
        'compiler'    => [],
        'compiler_lb' => [],
        'ovdb_lb'     => [],
      }
    )
  end

  it 'generates a role_map for small' do
    is_expected.to run.with_params(s_target_map).and_return(
      {
        'primary'     => [primary],
        'ovdb'        => [],
        'postgres'    => [],
        'compiler'    => [],
        'compiler_lb' => [],
        'ovdb_lb'     => [],
      }
    )
  end

  it 'generates a role_map for medium' do
    is_expected.to run.with_params(m_target_map).and_return(
      {
        'primary'     => [primary],
        'ovdb'        => [],
        'postgres'    => [],
        'compiler'    => [compiler1, compiler2],
        'compiler_lb' => [clb],
        'ovdb_lb'     => [],
      }
    )
  end

  it 'generates a role_map for large' do
    is_expected.to run.with_params(l_target_map).and_return(
      {
        'primary'     => [primary],
        'ovdb'        => [],
        'postgres'    => [postgres],
        'compiler'    => [compiler1, compiler2],
        'compiler_lb' => [clb],
        'ovdb_lb'     => [],
      }
    )
  end

  it 'generates a role_map for huge' do
    is_expected.to run.with_params(h_target_map).and_return(
      {
        'primary'     => [primary],
        'ovdb'        => [ovdb1, ovdb2],
        'postgres'    => [postgres],
        'compiler'    => [compiler1, compiler2],
        'compiler_lb' => [clb],
        'ovdb_lb'     => [ovdblb],
      }
    )
  end
end
