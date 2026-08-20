require 'spec_helper'

describe 'ovox::get_postgres_address' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  include_context('shared target maps')

  it 'returns localhost in a small cluster' do
    is_expected.to(
      run.with_params(s_target_map).and_return('localhost')
    )
  end

  it 'returns undef when no postgres server is defined' do
    is_expected.to(
      run.with_params(t_target_map).and_return(nil)
    )
  end

  it 'returns the postgres host when postgres is separate' do
    is_expected.to(
      run.with_params(h_target_map).and_return('postgres.spec')
    )
  end

  it 'returns the unmanaged host when postgres is unmanaged' do
    h_target_map['postgres_targets'] = []
    h_target_map['unmanaged_postgres_hosts'] = ['unmanaged.postgres.spec']
    is_expected.to(
      run.with_params(h_target_map).
        and_return('unmanaged.postgres.spec')
    )
  end

  it 'returns localhost in a custom configuration with separate ovdb/postgres host' do
    l_target_map['ovdb_targets'] = [postgres]
    is_expected.to(
      run.with_params(l_target_map).
        and_return('localhost')
    )
  end

  it 'returns the first postgres host' do
    h_target_map['postgres_targets'] = [postgres, a_target('postgres2.spec')]
    is_expected.to(
      run.with_params(h_target_map).
        and_return('postgres.spec')
    )
  end

  it 'returns the first unmanaged host' do
    h_target_map['postgres_targets'] = []
    h_target_map['unmanaged_postgres_hosts'] = ['unmanaged1.postgres.spec', 'unmanaged2.postgres.spec']
    is_expected.to(
      run.with_params(h_target_map).
        and_return('unmanaged1.postgres.spec')
    )
  end
end
