RSpec.shared_context('shared target maps') do
  let(:agent) { a_target('agent.spec') }
  let(:compiler1) { a_target('compiler1.spec') }
  let(:compiler2) { a_target('compiler2.spec') }
  let(:clb) { a_target('clb.spec') }
  let(:ovdb1) { a_target('ovdb1.spec') }
  let(:ovdb2) { a_target('ovdb2.spec') }
  let(:ovdblb) { a_target('ovdblb.spec') }
  let(:postgres) { a_target('postgres.spec') }
  let(:primary) { a_target('primary.spec') }

  let(:t_target_map) do
    {
      'primary_target'               => primary,
      'server_targets'               => [primary],
      'compiler_targets'             => [],
      'compiler_lb_targets'          => [],
      'ovdb_targets'                 => [],
      'ovdb_lb_targets'              => [],
      'postgres_targets'             => [],
      'agent_targets'                => [agent],
      'separate_ovdb_targets'        => [],
      'separate_postgres_targets'    => [],
      'all_additional_agent_targets' => [agent],
      'manage_postgres'              => true,
      'postgres_hosts'               => [],
    }
  end

  let(:s_target_map) do
    {
      'primary_target'               => primary,
      'server_targets'               => [primary],
      'compiler_targets'             => [],
      'compiler_lb_targets'          => [],
      'ovdb_targets'                 => [primary],
      'ovdb_lb_targets'              => [],
      'postgres_targets'             => [primary],
      'agent_targets'                => [agent],
      'separate_ovdb_targets'        => [],
      'separate_postgres_targets'    => [],
      'all_additional_agent_targets' => [agent],
      'manage_postgres'              => true,
      'postgres_hosts'               => [primary.to_s],
    }
  end

  let(:m_target_map) do
    {
      'primary_target'               => primary,
      'server_targets'               => [primary],
      'compiler_targets'             => [compiler1, compiler2],
      'compiler_lb_targets'          => [clb],
      'ovdb_targets'                 => [primary],
      'ovdb_lb_targets'              => [],
      'postgres_targets'             => [primary],
      'agent_targets'                => [agent],
      'separate_ovdb_targets'        => [],
      'separate_postgres_targets'    => [],
      'all_additional_agent_targets' => [agent, clb],
      'manage_postgres'              => true,
      'postgres_hosts'               => [primary.to_s],
    }
  end

  let(:l_target_map) do
    {
      'primary_target'               => primary,
      'server_targets'               => [primary],
      'compiler_targets'             => [compiler1, compiler2],
      'compiler_lb_targets'          => [clb],
      'ovdb_targets'                 => [primary],
      'ovdb_lb_targets'              => [],
      'postgres_targets'             => [postgres],
      'agent_targets'                => [agent],
      'separate_ovdb_targets'        => [],
      'separate_postgres_targets'    => [postgres],
      'all_additional_agent_targets' => [agent, clb, postgres],
      'manage_postgres'              => true,
      'postgres_hosts'               => [postgres.to_s],
    }
  end

  let(:h_target_map) do
    {
      'primary_target'               => primary,
      'server_targets'               => [primary],
      'compiler_targets'             => [compiler1, compiler2],
      'compiler_lb_targets'          => [clb],
      'ovdb_targets'                 => [ovdb1, ovdb2],
      'ovdb_lb_targets'              => [ovdblb],
      'postgres_targets'             => [postgres],
      'agent_targets'                => [agent],
      'separate_ovdb_targets'        => [ovdb1, ovdb2],
      'separate_postgres_targets'    => [postgres],
      'all_additional_agent_targets' => [agent, clb, ovdblb, postgres],
      'manage_postgres'              => true,
      'postgres_hosts'               => [postgres.to_s],
    }
  end

  # For ovox::subplans::determine_architecture
  let(:t_params) do
    {
      'primary_host'          => primary.to_s,
      'ovdb_hosts'            => [],
      'postgres_hosts'        => [],
      'compiler_hosts'        => [],
      'compiler_lb_hosts'     => [],
      'ovdb_lb_hosts'         => [],
      'agent_hosts'           => [agent.to_s],
      'manage_postgres'       => true,
      'compiler_pool_address' => nil,
      'ovdb_pool_address'     => nil,
    }
  end

  def unmanaged_postgres(target_map)
    target_map['manage_postgres'] = false
    target_map['postgres_targets'] = []
    target_map['separate_postgres_targets'] = []
    target_map
  end
end
