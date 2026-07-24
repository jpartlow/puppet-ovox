require 'spec_helper'

describe 'plan: ovox::subplans::determine_architecture' do
  include_context 'plan_init'

  RSpec.shared_examples('run arch plan') do
    it 'returns a target map' do
      result = run_plan('ovox::subplans::determine_architecture', params)

      expect(result.ok?).to(eq(true), result.value.to_s)
      expect(result.value).to eq(target_map)
    end
  end

  include_context 'shared target maps'

  context 'tiny' do
    let(:params) { t_params }
    let(:target_map) do
      {
        'server_targets'           => [primary],
        'ovdb_targets'             => [],
        'postgres_targets'         => [],
        'compiler_targets'         => [],
        'compiler_lb_targets'      => [],
        'ovdb_lb_targets'          => [],
        'agent_targets'            => [agent],
        'unmanaged_postgres_hosts' => [],
        'compiler_pool_address'    => nil,
        'ovdb_pool_address'        => nil,
      }
    end

    include_examples('run arch plan')
  end

  context 'small' do
    let(:params) { s_params }
    let(:target_map) do
      {
        'server_targets'           => [primary],
        'ovdb_targets'             => [primary],
        'postgres_targets'         => [primary],
        'compiler_targets'         => [],
        'compiler_lb_targets'      => [],
        'ovdb_lb_targets'          => [],
        'agent_targets'            => [agent],
        'unmanaged_postgres_hosts' => [],
        'compiler_pool_address'    => nil,
        'ovdb_pool_address'        => nil,
      }
    end

    include_examples('run arch plan')
  end

  context 'medium' do
    let(:params) { m_params }
    let(:target_map) do
      {
        'server_targets'           => [primary],
        'ovdb_targets'             => [primary],
        'postgres_targets'         => [primary],
        'compiler_targets'         => [compiler1, compiler2],
        'compiler_lb_targets'      => [clb],
        'ovdb_lb_targets'          => [],
        'agent_targets'            => [agent],
        'unmanaged_postgres_hosts' => [],
        'compiler_pool_address'    => nil,
        'ovdb_pool_address'        => nil,
      }
    end

    include_examples('run arch plan')
  end

  context 'large' do
    let(:params) { l_params }
    let(:target_map) do
      {
        'server_targets'           => [primary],
        'ovdb_targets'             => [primary],
        'postgres_targets'         => [postgres],
        'compiler_targets'         => [compiler1, compiler2],
        'compiler_lb_targets'      => [clb],
        'ovdb_lb_targets'          => [],
        'agent_targets'            => [agent],
        'unmanaged_postgres_hosts' => [],
        'compiler_pool_address'    => nil,
        'ovdb_pool_address'        => nil,
      }
    end

    include_examples('run arch plan')
  end

  context 'huge' do
    let(:params) { h_params }
    let(:target_map) do
      {
        'server_targets'           => [primary],
        'ovdb_targets'             => [ovdb1, ovdb2],
        'postgres_targets'         => [postgres],
        'compiler_targets'         => [compiler1, compiler2],
        'compiler_lb_targets'      => [clb],
        'ovdb_lb_targets'          => [ovdblb],
        'agent_targets'            => [agent],
        'unmanaged_postgres_hosts' => [],
        'compiler_pool_address'    => nil,
        'ovdb_pool_address'        => nil,
      }
    end

    include_examples('run arch plan')
  end

  context 'custom' do
    let(:params) do
      l_params['ovdb_hosts'] = [postgres.to_s]
      l_params
    end
    let(:target_map) do
      {
        'server_targets'           => [primary],
        'ovdb_targets'             => [postgres],
        'postgres_targets'         => [postgres],
        'compiler_targets'         => [compiler1, compiler2],
        'compiler_lb_targets'      => [clb],
        'ovdb_lb_targets'          => [],
        'agent_targets'            => [agent],
        'unmanaged_postgres_hosts' => [],
        'compiler_pool_address'    => nil,
        'ovdb_pool_address'        => nil,
      }
    end

    include_examples('run arch plan')
  end
end
