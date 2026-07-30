require 'spec_helper'

describe 'ovox::derive_profile_flags' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  include_context('shared target maps')

  it 'returns flags for a tiny arch' do
    is_expected.to run.with_params(t_target_map).and_return(
      {
        'ov_role::primary::install_ovdb'     => false,
        'ov_role::primary::install_postgres' => false,
      }
    )
  end

  it 'returns flags for a small arch' do
    is_expected.to run.with_params(s_target_map).and_return(
      {
        'ov_role::primary::install_ovdb'     => true,
        'ov_role::primary::install_postgres' => true,
      }
    )
  end

  it 'returns flags for a large arch' do
    is_expected.to run.with_params(l_target_map).and_return(
      {
        'ov_role::primary::install_ovdb'     => true,
        'ov_role::primary::install_postgres' => false,
      }
    )
  end

  it 'returns flags for a huge arch' do
    is_expected.to run.with_params(h_target_map).and_return(
      {
        'ov_role::primary::install_ovdb'     => false,
        'ov_role::primary::install_postgres' => false,
        'ov_role::ovdb::install_postgres'    => false,
      }
    )
  end

  it 'returns flags for a custom arch with ovdb/postgres nodes' do
    l_target_map['ovdb_targets'] = [postgres]

    is_expected.to run.with_params(l_target_map).and_return(
      {
        'ov_role::primary::install_ovdb' => false,
        'ov_role::primary::install_postgres' => false,
        'ov_role::ovdb::install_postgres' => true,
      }
    )
  end
end
