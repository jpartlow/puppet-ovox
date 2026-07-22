require 'spec_helper'

describe 'plan: ovox::subplans::determine_architecture' do
  include_context 'plan_init'
  include_context 'shared target maps'

  context 'tiny' do
    let(:params) { t_params }

    it 'returns an arch map' do
      result = run_plan('ovox::subplans::determine_architecture', params)

      expect(result.ok?).to(eq(true), result.value.to_s)
      arch_map = result.value
      expect(arch_map.keys).to(
        eq(['architecture', 'target_map', 'role_map', 'profile_flags'])
      )
      expect(arch_map['architecture']).to eq('tiny')
      expect(arch_map['target_map']).to eq(
        {
          'primary_target'               => primary,
          'server_targets'               => [primary],
          'ovdb_targets'                 => [],
          'postgres_targets'             => [],
          'compiler_targets'             => [],
          'compiler_lb_targets'          => [],
          'ovdb_lb_targets'              => [],
          'separate_ovdb_targets'        => [],
          'separate_postgres_targets'    => [],
          'agent_targets'                => [agent],
          'all_additional_agent_targets' => [agent],
          'manage_postgres'              => true,
          'postgres_hosts'               => [],
        }
      )
      expect(arch_map['role_map']).to match(
        {
          'primary'     => [primary],
          'ovdb'        => [],
          'postgres'    => [],
          'compiler'    => [],
          'compiler_lb' => [],
          'ovdb_lb'     => [],
        }
      )
      expect(arch_map['profile_flags']).to match(
        {
          'ov_role::primary::openvox_server' => true,
        }
      )
    end
  end

  context 'small' do
    let(:params) { s_params }

    it 'returns an arch map' do
      result = run_plan('ovox::subplans::determine_architecture', params)

      expect(result.ok?).to(eq(true), result.value.to_s)
      arch_map = result.value
      expect(arch_map.keys).to(
        eq(['architecture', 'target_map', 'role_map', 'profile_flags'])
      )
      expect(arch_map['architecture']).to eq('small')
      expect(arch_map['target_map']).to eq(
        {
          'primary_target'               => primary,
          'server_targets'               => [primary],
          'ovdb_targets'                 => [primary],
          'postgres_targets'             => [primary],
          'compiler_targets'             => [],
          'compiler_lb_targets'          => [],
          'ovdb_lb_targets'              => [],
          'separate_ovdb_targets'        => [],
          'separate_postgres_targets'    => [],
          'agent_targets'                => [agent],
          'all_additional_agent_targets' => [agent],
          'manage_postgres'              => true,
          'postgres_hosts'               => [primary.to_s],
        }
      )
      expect(arch_map['role_map']).to match(
        {
          'primary'     => [primary],
          'ovdb'        => [],
          'postgres'    => [],
          'compiler'    => [],
          'compiler_lb' => [],
          'ovdb_lb'     => [],
        }
      )
      expect(arch_map['profile_flags']).to match(
        {
          'ov_role::primary::install_server'   => true,
          'ov_role::primary::install_ovdb'     => true,
          'ov_role::primary::install_postgres' => true,
        }
      )
    end
  end

  context 'medium' do
    it 'returns an arch_map'
  end

  context 'large' do
    it 'returns an arch_map'
  end

  context 'huge' do
    it 'returns an arch_map'
  end

  context 'custom' do
    it 'returns an arch_map with ovdb and postgres on a separate node'
  end
end
