require 'spec_helper'

describe 'ovox::validate_architecture' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  include_context('shared target maps')

  let(:valid) do
    {
      'warnings'    => [],
      'ambiguities' => [],
      'errors'      => [],
    }
  end

  it 'returns an empty error for set arches without overlapping roles' do
    is_expected.to run.with_params(t_target_map).and_return(valid)
    is_expected.to run.with_params(s_target_map).and_return(valid)
    is_expected.to run.with_params(m_target_map).and_return(valid)
    is_expected.to run.with_params(l_target_map).and_return(valid)
    is_expected.to run.with_params(h_target_map).and_return(valid)
  end

  context 'warnings' do
    it 'warns if no primary' do
      t_target_map['primary_targets'] = []
      info = call_function('ovox::validate_architecture', t_target_map)
      expect(info['warnings']).to match([%r{No defined primary openvox-server targets}])
      expect(info['ambiguities']).to be_empty
      expect(info['errors']).to be_empty
    end

    it 'warns if primary/postgres and separate ovdb' do
      s_target_map['ovdb_targets'] = [ovdb1]
      info = call_function('ovox::validate_architecture', s_target_map)
      expect(info['warnings']).to match([%r{Primary has postgresql, but openvoxdb is on a separate node}])
      expect(info['ambiguities']).to be_empty
      expect(info['errors']).to be_empty
    end
  end

  context 'ambiguities' do
    it 'returns an error if more than one primary is defined' do
      t_target_map['primary_targets'] = [primary, a_target('primary2.spec')]
      info = call_function('ovox::validate_architecture', t_target_map)
      expect(info['ambiguities']).to match([%r{More than one primary}])
      expect(info['warnings']).to be_empty
      expect(info['errors']).to be_empty
    end

    it 'returns an error if more than one postgres is defined' do
      l_target_map['postgres_targets'] = [postgres, a_target('postgres2.spec')]
      info = call_function('ovox::validate_architecture', l_target_map)
      expect(info['ambiguities']).to match([%r{More than one PostgreSQL}])
      expect(info['warnings']).to be_empty
      expect(info['errors']).to be_empty
    end

    it 'returns an error if ovdb present and postgres is missing' do
      s_target_map['postgres_targets'] = []
      info = call_function('ovox::validate_architecture', s_target_map)
      expect(info['ambiguities']).to match([%r{Openvoxdb nodes defined, but no Postgres}])
      expect(info['warnings']).to be_empty
      expect(info['errors']).to be_empty
    end

    it 'returns an error if postgres is present and ovdb is missing' do
      s_target_map['ovdb_targets'] = []
      info = call_function('ovox::validate_architecture', s_target_map)
      expect(info['ambiguities']).to match([%r{Postgres nodes defined, but no openvoxdb}])
      expect(info['warnings']).to be_empty
      expect(info['errors']).to be_empty

      info = call_function('ovox::validate_architecture', unmanaged_postgres(s_target_map))
      expect(info['ambiguities']).to match([%r{Postgres nodes defined, but no openvoxdb}])
      expect(info['warnings']).to be_empty
      expect(info['errors']).to be_empty
    end

    it 'returns an error if compilers are present and no lb or pool address' do
      m_target_map['compiler_lb_targets'] = []
      info = call_function('ovox::validate_architecture', m_target_map)
      expect(info['ambiguities']).to match([%r{Compilers defined, but no.*load-balancer}])
      expect(info['warnings']).to be_empty
      expect(info['errors']).to be_empty

      m_target_map['compiler_pool_address'] = 'foo.lb.spec'
      is_expected.to run.with_params(m_target_map).and_return(valid)
    end

    it 'returns an error if multiple ovdbs are present and no lb or pool address' do
      h_target_map['ovdb_lb_targets'] = []
      info = call_function('ovox::validate_architecture', h_target_map)
      expect(info['ambiguities']).to match([%r{Multiple Openvoxdb nodes defined, but no.*load-balancer}])
      expect(info['warnings']).to be_empty
      expect(info['errors']).to be_empty

      h_target_map['ovdb_pool_address'] = 'foo.lb.spec'
      is_expected.to run.with_params(h_target_map).and_return(valid)
    end

    it 'returns an error if postgres_targets and unmanaged_postgres_hosts defined' do
      s_target_map['unmanaged_postgres_hosts'] = ['some.postgres.spec']
      info = call_function('ovox::validate_architecture', s_target_map)
      expect(info['ambiguities']).to match([%r{Both internal and external PostgreSQL}])
      expect(info['warnings']).to be_empty
      expect(info['errors']).to be_empty
    end

    it 'returns an error if only some ovdbs are also postgres' do
      h_target_map['postgres_targets'] = [ovdb2]

      info = call_function('ovox::validate_architecture', h_target_map)
      expect(info['ambiguities']).to match(
        [
          %r{Only some Openvoxdb targets.*are also PostgreSQL targets},
        ]
      )
      expect(info['warnings']).to be_empty
      expect(info['errors']).to be_empty
    end

    it 'returns an empty error set for a separate ovdb/postgres node' do
      l_target_map['ovdb_targets'] = [postgres]
      is_expected.to run.with_params(l_target_map).and_return(valid)
    end
  end

  context 'errors' do
    it 'returns an error if compilers overlap another role' do
      m_target_map['compiler_targets'] << m_target_map['primary_targets'][0]

      info = call_function('ovox::validate_architecture', m_target_map)
      expect(info['errors']).to match([%r{compiler hostnames should be unique}])
      expect(info['warnings']).to be_empty
      expect(info['ambiguities']).to be_empty
    end

    it 'returns an error if compiler_lbs overlap another role' do
      h_target_map['ovdb_targets'] << h_target_map['compiler_lb_targets'][0]

      info = call_function('ovox::validate_architecture', h_target_map)
      expect(info['errors']).to match([%r{compiler_lb hostnames should be unique}])
      expect(info['warnings']).to be_empty
      expect(info['ambiguities']).to be_empty
    end

    it 'returns an error if ovdb_lbs overlap another role' do
      h_target_map['compiler_lb_targets'] = h_target_map['ovdb_lb_targets']

      info = call_function('ovox::validate_architecture', h_target_map)
      expect(info['errors']).to match(
        [
          %r{compiler_lb hostnames should be unique},
          %r{ovdb_lb hostnames should be unique},
        ]
      )
      expect(info['warnings']).to be_empty
      expect(info['ambiguities']).to be_empty
    end
  end

  context 'mixed' do
    it 'returns errors of all classes' do
      h_target_map['primary_targets'] = [primary, a_target('primary2.spec')]
      h_target_map['ovdb_targets'] = [primary, ovdb2]
      h_target_map['postgres_targets'] = [primary]
      h_target_map['compiler_lb_targets'] = [primary]

      info = call_function('ovox::validate_architecture', h_target_map)
      expect(info).to match(
        {
          'ambiguities' => [
            %r{More than one primary},
            %r{Only some Primary targets.*are also Openvoxdb targets},
            %r{Only some Primary targets.* are also PostgreSQL targets},
          ],
          'errors'      => [%r{compiler_lb hostnames should be unique}],
          'warnings'    => [%r{Primary has postgresql.*but openvoxdb.*separate}],
        }
      )
    end
  end
end
