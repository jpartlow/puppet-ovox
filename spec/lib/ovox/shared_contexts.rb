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

  # For testing functions that take a TargetMap defining cluster
  # architecture.
  let(:t_target_map) do
    {
      'primary_targets'          => [primary],
      'compiler_targets'         => [],
      'compiler_lb_targets'      => [],
      'ovdb_targets'             => [],
      'ovdb_lb_targets'          => [],
      'postgres_targets'         => [],
      'unmanaged_postgres_hosts' => [],
      'agent_targets'            => [agent],
      'compiler_pool_address'    => nil,
      'ovdb_pool_address'        => nil,
    }
  end

  let(:s_target_map) do
    {
      'primary_targets'          => [primary],
      'compiler_targets'         => [],
      'compiler_lb_targets'      => [],
      'ovdb_targets'             => [primary],
      'ovdb_lb_targets'          => [],
      'postgres_targets'         => [primary],
      'unmanaged_postgres_hosts' => [],
      'agent_targets'            => [agent],
      'compiler_pool_address'    => nil,
      'ovdb_pool_address'        => nil,
    }
  end

  let(:m_target_map) do
    {
      'primary_targets'          => [primary],
      'compiler_targets'         => [compiler1, compiler2],
      'compiler_lb_targets'      => [clb],
      'ovdb_targets'             => [primary],
      'ovdb_lb_targets'          => [],
      'postgres_targets'         => [primary],
      'unmanaged_postgres_hosts' => [],
      'agent_targets'            => [agent],
      'compiler_pool_address'    => nil,
      'ovdb_pool_address'        => nil,
    }
  end

  let(:l_target_map) do
    {
      'primary_targets'          => [primary],
      'compiler_targets'         => [compiler1, compiler2],
      'compiler_lb_targets'      => [clb],
      'ovdb_targets'             => [primary],
      'ovdb_lb_targets'          => [],
      'postgres_targets'         => [postgres],
      'unmanaged_postgres_hosts' => [],
      'agent_targets'            => [agent],
      'compiler_pool_address'    => nil,
      'ovdb_pool_address'        => nil,
    }
  end

  let(:h_target_map) do
    {
      'primary_targets'          => [primary],
      'compiler_targets'         => [compiler1, compiler2],
      'compiler_lb_targets'      => [clb],
      'ovdb_targets'             => [ovdb1, ovdb2],
      'ovdb_lb_targets'          => [ovdblb],
      'postgres_targets'         => [postgres],
      'unmanaged_postgres_hosts' => [],
      'agent_targets'            => [agent],
      'compiler_pool_address'    => nil,
      'ovdb_pool_address'        => nil,
    }
  end

  # Variations
  let(:just_agents_target_map) do
    {
      'primary_targets'          => [],
      'compiler_targets'         => [],
      'compiler_lb_targets'      => [],
      'ovdb_targets'             => [],
      'ovdb_lb_targets'          => [],
      'postgres_targets'         => [],
      'unmanaged_postgres_hosts' => [],
      'agent_targets'            => [agent],
      'compiler_pool_address'    => nil,
      'ovdb_pool_address'        => nil,
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

  let(:s_params) do
    {
      'primary_host'          => primary.to_s,
      'ovdb_hosts'            => [primary.to_s],
      'postgres_hosts'        => [primary.to_s],
      'compiler_hosts'        => [],
      'compiler_lb_hosts'     => [],
      'ovdb_lb_hosts'         => [],
      'agent_hosts'           => [agent.to_s],
      'manage_postgres'       => true,
      'compiler_pool_address' => nil,
      'ovdb_pool_address'     => nil,
    }
  end

  let(:m_params) do
    {
      'primary_host'          => primary.to_s,
      'ovdb_hosts'            => [primary.to_s],
      'postgres_hosts'        => [primary.to_s],
      'compiler_hosts'        => [compiler1.to_s, compiler2.to_s ],
      'compiler_lb_hosts'     => [clb.to_s],
      'ovdb_lb_hosts'         => [],
      'agent_hosts'           => [agent.to_s],
      'manage_postgres'       => true,
      'compiler_pool_address' => nil,
      'ovdb_pool_address'     => nil,
    }
  end

  let(:l_params) do
    {
      'primary_host'          => primary.to_s,
      'ovdb_hosts'            => [primary.to_s],
      'postgres_hosts'        => [postgres.to_s],
      'compiler_hosts'        => [compiler1.to_s, compiler2.to_s ],
      'compiler_lb_hosts'     => [clb.to_s],
      'ovdb_lb_hosts'         => [],
      'agent_hosts'           => [agent.to_s],
      'manage_postgres'       => true,
      'compiler_pool_address' => nil,
      'ovdb_pool_address'     => nil,
    }
  end

  let(:h_params) do
    {
      'primary_host'          => primary.to_s,
      'ovdb_hosts'            => [ovdb1.to_s, ovdb2.to_s],
      'postgres_hosts'        => [postgres.to_s],
      'compiler_hosts'        => [compiler1.to_s, compiler2.to_s ],
      'compiler_lb_hosts'     => [clb.to_s],
      'ovdb_lb_hosts'         => [ovdblb.to_s],
      'agent_hosts'           => [agent.to_s],
      'manage_postgres'       => true,
      'compiler_pool_address' => nil,
      'ovdb_pool_address'     => nil,
    }
  end

  def unmanaged_postgres(target_map)
    target_map['unmanaged_postgres_hosts'] = target_map['postgres_targets'].map(&:to_s)
    target_map['postgres_targets'] = []
    target_map
  end
end
