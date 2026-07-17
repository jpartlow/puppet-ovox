require 'spec_helper'

describe 'plan: ovox::subplans::determine_architecture' do
  include_context 'plan_init'
  include_context 'shared target maps'

  context 'tiny' do
    let(:params) { t_params }

    it 'runs' do
      result = run_plan('ovox::subplans::determine_architecture', params)

      expect(result.ok?).to(eq(true), result.value.to_s)
      arch_map = result.value
      expect(arch_map.keys).to(
        eq(['architecture', 'target_map', 'role_map'])
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
    end
  end
end
