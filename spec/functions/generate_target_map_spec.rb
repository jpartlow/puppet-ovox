require 'spec_helper'

# NOTE: rspec-puppet run.and_return() matcher is a very blunt tool
# that does not provide good visual diffs of complex structures
# returned by functions. Bypassing it with direct use of call_function()
# followed by use of rspec matchers so that differences are easier to see.
describe 'ovox::generate_target_map' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  let(:t_host_map) do
    {
      'primary_host'      => 'primary.spec',
      'ovdb_hosts'        => [],
      'postgres_hosts'    => [],
      'compiler_hosts'    => [],
      'compiler_lb_hosts' => [],
      'ovdb_lb_hosts'     => [],
      'agent_hosts'       => 'agent.spec',
    }
  end
  let(:m_host_map) do
    {
      'primary_host'      => 'primary.spec',
      'ovdb_hosts'        => 'primary.spec',
      'postgres_hosts'    => 'primary.spec',
      'compiler_hosts'    => ['compiler1.spec', 'compiler2.spec'],
      'compiler_lb_hosts' => ['clb.spec'],
      'ovdb_lb_hosts'     => [],
      'agent_hosts'       => 'agent.spec',
    }
  end
  let(:h_host_map) do
    {
      'primary_host'      => 'primary.spec',
      'ovdb_hosts'        => ['ovdb1.spec', 'ovdb2.spec'],
      'postgres_hosts'    => 'cloud.postgres.spec',
      'compiler_hosts'    => ['compiler1.spec', 'compiler2.spec'],
      'compiler_lb_hosts' => ['clb.spec'],
      'ovdb_lb_hosts'     => ['ovdblb.spec'],
      'agent_hosts'       => 'agent.spec',
    }
  end

  context 'with postgres' do
    it 'returns a target_map for a medium cluster' do
      result = call_function('ovox::generate_target_map', m_host_map, true)
      expect(result).to match(
        {
          'primary_target'               => a_target('primary.spec'),
          'server_targets'               => [a_target('primary.spec')],
          'compiler_targets'             => match_array([a_target('compiler1.spec'), a_target('compiler2.spec')]),
          'compiler_lb_targets'          => [a_target('clb.spec')],
          'ovdb_targets'                 => [a_target('primary.spec')],
          'ovdb_lb_targets'              => [],
          'postgres_targets'             => [a_target('primary.spec')],
          'agent_targets'                => [a_target('agent.spec')],
          'separate_ovdb_targets'        => [],
          'separate_postgres_targets'    => [],
          'all_additional_agent_targets' => match_array([a_target('clb.spec'), a_target('agent.spec')]),
          'manage_postgres'              => true,
          'postgres_hosts'               => ['primary.spec'],
        }
      )
    end
  end

  context 'with unmanaged postgres' do
    it 'returns a target_map for a huge cluster without a postgres target' do
      result = call_function('ovox::generate_target_map', h_host_map, false)
      expect(result).to match(
        {
          'primary_target'               => a_target('primary.spec'),
          'server_targets'               => [a_target('primary.spec')],
          'compiler_targets'             => [a_target('compiler1.spec'), a_target('compiler2.spec')],
          'compiler_lb_targets'          => [a_target('clb.spec')],
          'ovdb_targets'                 => [a_target('ovdb1.spec'), a_target('ovdb2.spec')],
          'ovdb_lb_targets'              => [a_target('ovdblb.spec')],
          'postgres_targets'             => [],
          'agent_targets'                => [a_target('agent.spec')],
          'separate_ovdb_targets'        => [a_target('ovdb1.spec'), a_target('ovdb2.spec')],
          'separate_postgres_targets'    => [],
          'all_additional_agent_targets' => [a_target('agent.spec'), a_target('clb.spec'), a_target('ovdblb.spec')],
          'manage_postgres'              => false,
          'postgres_hosts'               => ['cloud.postgres.spec'],
        }
      )
    end
  end

  context 'without postgres' do
    it 'returns a target_map for a tiny cluster' do
      result = call_function('ovox::generate_target_map', t_host_map, true)
      expect(result).to match(
        {
          'primary_target'               => a_target('primary.spec'),
          'server_targets'               => [a_target('primary.spec')],
          'compiler_targets'             => [],
          'compiler_lb_targets'          => [],
          'ovdb_targets'                 => [],
          'ovdb_lb_targets'              => [],
          'postgres_targets'             => [],
          'agent_targets'                => [a_target('agent.spec')],
          'separate_ovdb_targets'        => [],
          'separate_postgres_targets'    => [],
          'all_additional_agent_targets' => [a_target('agent.spec')],
          'manage_postgres'              => true,
          'postgres_hosts'               => [],
        }
      )
    end
  end
end
