require 'spec_helper'

describe 'ovox::validate_architecture' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  include_context('shared target maps')

  it 'returns an empty error for set arches without overlapping roles' do
    is_expected.to run.with_params(t_target_map).and_return([])
    is_expected.to run.with_params(s_target_map).and_return([])
    is_expected.to run.with_params(m_target_map).and_return([])
    is_expected.to run.with_params(l_target_map).and_return([])
    is_expected.to run.with_params(h_target_map).and_return([])
  end

  context 'custom arch' do
    it 'raises an error if ovdb present and postgres is missing' do
      s_target_map['postgres_targets'] = []
      $errs = call_function('ovox::validate_architecture', s_target_map)
      expect($errs).to match([%r{Openvoxdb nodes defined, but no Postgres}])
    end

    it 'raises an error if postgres is present and ovdb is missing' do
      s_target_map['ovdb_targets'] = []
      $errs = call_function('ovox::validate_architecture', s_target_map)
      expect($errs).to match([%r{Postgres nodes defined, but no openvoxdb}])
      $errs = call_function('ovox::validate_architecture', unmanaged_postgres(s_target_map))
      expect($errs).to match([%r{Postgres nodes defined, but no openvoxdb}])
    end

    it 'raises an error if compilers are present and no lb or pool address' do
      m_target_map['compiler_lb_targets'] = []
      $errs = call_function('ovox::validate_architecture', m_target_map)
      expect($errs).to match([%r{Compilers defined, but no.*load-balancer}])
      m_target_map['compiler_pool_address'] = 'foo.lb.spec'
      is_expected.to run.with_params(m_target_map).and_return([])
    end

    it 'raises an error if multiple ovdbs are present and no lb or pool address' do
      h_target_map['ovdb_lb_targets'] = []
      $errs = call_function('ovox::validate_architecture', h_target_map)
      expect($errs).to match([%r{Multiple Openvoxdb nodes defined, but no.*load-balancer}])

      h_target_map['ovdb_pool_address'] = 'foo.lb.spec'
      is_expected.to run.with_params(h_target_map).and_return([])
    end

    it 'raises an error if postgres_targets and unmanaged_postgres_hosts defined' do
      s_target_map['unmanaged_postgres_hosts'] = ['some.postgres.spec']
      $errs = call_function('ovox::validate_architecture', s_target_map)
      expect($errs).to match([%r{Both internal and external PostgreSQL}])
    end
  end

  context 'overlapping roles' do
    it 'raises an error if compilers overlap another role' do
      m_target_map['compiler_targets'] << m_target_map['primary_targets'][0]

      $errs = call_function('ovox::validate_architecture', m_target_map)
      expect($errs).to match([%r{compiler hostnames should be unique}])
    end

    it 'raises an error if compiler_lbs overlap another role' do
      h_target_map['ovdb_targets'] << h_target_map['compiler_lb_targets'][0]

      $errs = call_function('ovox::validate_architecture', h_target_map)
      expect($errs).to match([%r{compiler_lb hostnames should be unique}])
    end

    it 'raises an error if ovdb_lbs overlap another role' do
      h_target_map['compiler_lb_targets'] = h_target_map['ovdb_lb_targets']

      $errs = call_function('ovox::validate_architecture', h_target_map)
      expect($errs).to match(
        [
          %r{compiler_lb hostnames should be unique},
          %r{ovdb_lb hostnames should be unique},
        ]
      )
    end
  end
end
