require 'spec_helper'

describe 'ovox::generate_hiera_layers' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  include_context('shared target maps')

  let(:hiera_cluster_dir) { '/tmp/hiera/cluster/foo' }
  let(:base_config) do
    {
      'puppet::client_package'             => 'openvox-agent',
      'puppet::server_package'             => 'openvox-server',
      'puppet::server_foreman'             => false,
    }
  end
  let(:ovdb_common_config) do
    {
      'openvoxdb::database::postgresql::postgresql_ssl_on' => true,
      'openvoxdb::server::postgresql::postgresql_ssl_on' => true,
    }
  end
  let(:ovdb_server_common_config) do
    {
      'puppet::server_reports' => 'puppetdb',
      'puppet::server_storeconfigs' => true,
    }
  end
  let(:common_config) do
    base_config
      .merge(ovdb_common_config)
      .merge(ovdb_server_common_config)
  end

  it 'returns hiera config for a tiny arch' do
    is_expected.to(
      run.with_params(t_target_map, hiera_cluster_dir, {})
        .and_return(
          {
            "#{hiera_cluster_dir}/ovox.yaml" => {
              'ov_role::primary::install_ovdb'     => false,
              'ov_role::primary::install_postgres' => false,
            }.merge(base_config),
            "#{hiera_cluster_dir}/role/compiler.yaml" => {},
          }
        )
    )
  end

  it 'returns hiera config for a small arch' do
    hiera_map = call_function(
      'ovox::generate_hiera_layers',
      s_target_map,
      hiera_cluster_dir,
      {}
    )
    expect(hiera_map).to match(
      {
        "#{hiera_cluster_dir}/ovox.yaml" => instance_of(Hash),
        "#{hiera_cluster_dir}/role/compiler.yaml" => {},
      }
    )
    expect(hiera_map["#{hiera_cluster_dir}/ovox.yaml"]).to match(
      {
        'ov_role::primary::install_ovdb'     => true,
        'ov_role::primary::install_postgres' => true,
        'openvoxdb::database::postgresql::listen_address' => 'localhost',
        'openvoxdb::database::postgresql::puppetdb_server' => 'primary.spec',
        'openvoxdb::database::postgresql::postgresql_ssl_on' => true,
        'ov_profile::postgres::additional_ovdb_servers' => [],
        'openvoxdb::server::postgresql::postgresql_ssl_on' => true,
        'openvoxdb::server::database_host' => 'localhost',
        'puppet::server::puppetdb::server' => 'primary.spec',
      }.merge(common_config),
    )
  end

  it 'returns hiera config for a medium arch' do
    hiera_map = call_function(
      'ovox::generate_hiera_layers',
      m_target_map,
      hiera_cluster_dir,
      {
        'postgres_version' => '16',
      }
    )
    expect(hiera_map).to match(
      {
        "#{hiera_cluster_dir}/ovox.yaml" => instance_of(Hash),
        "#{hiera_cluster_dir}/role/compiler.yaml" => {
          'puppet::ca_server' => 'primary.spec',
          'puppet::server_ca' => false,
        },
      }
    )
    expect(hiera_map["#{hiera_cluster_dir}/ovox.yaml"]).to match(
      {
        'ov_role::primary::install_ovdb'     => true,
        'ov_role::primary::install_postgres' => true,
        'openvoxdb::database::postgresql::listen_address' => 'localhost',
        'openvoxdb::database::postgresql::postgres_version' => '16',
        'openvoxdb::database::postgresql::puppetdb_server' => 'primary.spec',
        'openvoxdb::database::postgresql::postgresql_ssl_on' => true,
        'ov_profile::postgres::additional_ovdb_servers' => [],
        'openvoxdb::server::postgresql::postgresql_ssl_on' => true,
        'openvoxdb::server::database_host' => 'localhost',
        'puppet::server::puppetdb::server' => 'primary.spec',
      }.merge(common_config),
    )
  end

  it 'returns hiera config for a large arch' do
    hiera_map = call_function(
      'ovox::generate_hiera_layers',
      l_target_map,
      hiera_cluster_dir,
      {}
    )
    expect(hiera_map).to match(
      {
        "#{hiera_cluster_dir}/ovox.yaml" => instance_of(Hash),
        "#{hiera_cluster_dir}/role/compiler.yaml" => {
          'puppet::ca_server' => 'primary.spec',
          'puppet::server_ca' => false,
        },
      }
    )
    expect(hiera_map["#{hiera_cluster_dir}/ovox.yaml"]).to match(
      {
        'ov_role::primary::install_ovdb'     => true,
        'ov_role::primary::install_postgres' => false,
        'openvoxdb::database::postgresql::listen_address' => 'postgres.spec',
        'openvoxdb::database::postgresql::puppetdb_server' => 'primary.spec',
        'openvoxdb::database::postgresql::postgresql_ssl_on' => true,
        'ov_profile::postgres::additional_ovdb_servers' => [],
        'openvoxdb::server::postgresql::postgresql_ssl_on' => true,
        'openvoxdb::server::database_host' => 'postgres.spec',
        'puppet::server::puppetdb::server' => 'primary.spec',
      }.merge(common_config),
    )
  end

  it 'returns hiera config for a huge arch' do
    hiera_map = call_function(
      'ovox::generate_hiera_layers',
      h_target_map,
      hiera_cluster_dir,
      {}
    )
    expect(hiera_map).to match(
      {
        "#{hiera_cluster_dir}/ovox.yaml" => instance_of(Hash),
        "#{hiera_cluster_dir}/role/compiler.yaml" => {
          'puppet::ca_server' => 'primary.spec',
          'puppet::server_ca' => false,
        },
      }
    )
    expect(hiera_map["#{hiera_cluster_dir}/ovox.yaml"]).to match(
      {
        'ov_role::ovdb::install_postgres'    => false,
        'ov_role::primary::install_ovdb'     => false,
        'ov_role::primary::install_postgres' => false,
        'openvoxdb::database::postgresql::listen_address' => 'postgres.spec',
        'openvoxdb::database::postgresql::puppetdb_server' => 'ovdb1.spec',
        'openvoxdb::database::postgresql::postgresql_ssl_on' => true,
        'ov_profile::postgres::additional_ovdb_servers' => ['ovdb2.spec'],
        'openvoxdb::server::postgresql::postgresql_ssl_on' => true,
        'openvoxdb::server::database_host' => 'postgres.spec',
        'puppet::server::puppetdb::server' => 'ovdblb.spec',
      }.merge(common_config),
    )
  end

  it 'configures for an external postgres' do
    l_target_map['postgres_targets'] = []
    l_target_map['unmanaged_postgres_hosts'] =
      ['unmanaged.postgres.spec']

    hiera_map = call_function(
      'ovox::generate_hiera_layers',
      l_target_map,
      hiera_cluster_dir,
      {}
    )
    expect(hiera_map).to match(
      {
        "#{hiera_cluster_dir}/ovox.yaml" => instance_of(Hash),
        "#{hiera_cluster_dir}/role/compiler.yaml" => {
          'puppet::ca_server' => 'primary.spec',
          'puppet::server_ca' => false,
        },
      }
    )
    expect(hiera_map["#{hiera_cluster_dir}/ovox.yaml"]).to match(
      {
        'ov_role::primary::install_ovdb'     => true,
        'ov_role::primary::install_postgres' => false,
        'openvoxdb::server::database_host' => 'unmanaged.postgres.spec',
        'puppet::server::puppetdb::server' => 'primary.spec',
      }.merge(base_config)
       .merge(ovdb_server_common_config),
    )
  end

  context 'with a custom arch' do
    it 'returns config for a simple 3 way split' do
      s_target_map['ovdb_targets'] = [ovdb1]
      s_target_map['postgres_targets'] = [postgres]

      hiera_map = call_function(
        'ovox::generate_hiera_layers',
        s_target_map,
        hiera_cluster_dir,
        {}
      )
      expect(hiera_map).to match(
        {
          "#{hiera_cluster_dir}/ovox.yaml" => instance_of(Hash),
          "#{hiera_cluster_dir}/role/compiler.yaml" => {},
        }
      )
      expect(hiera_map["#{hiera_cluster_dir}/ovox.yaml"]).to match(
        {
          'ov_role::ovdb::install_postgres'    => false,
          'ov_role::primary::install_ovdb'     => false,
          'ov_role::primary::install_postgres' => false,
          'openvoxdb::database::postgresql::listen_address' => 'postgres.spec',
          'openvoxdb::database::postgresql::puppetdb_server' => 'ovdb1.spec',
          'openvoxdb::server::database_host' => 'postgres.spec',
          'ov_profile::postgres::additional_ovdb_servers' => [],
          'puppet::server::puppetdb::server' => 'ovdb1.spec',
        }.merge(common_config),
      )
    end
  end

  context 'with an ambiguous arch' do
    it 'returns only basic profile config' do
      l_target_map['primary_targets'] = [primary, a_target('primary2')]

      hiera_map = call_function(
        'ovox::generate_hiera_layers',
        l_target_map,
        hiera_cluster_dir,
        {}
      )
      expect(hiera_map).to match(
        {
          "#{hiera_cluster_dir}/ovox.yaml" => instance_of(Hash),
          "#{hiera_cluster_dir}/role/compiler.yaml" => {},
        }
      )
      expect(hiera_map["#{hiera_cluster_dir}/ovox.yaml"]).to match(
        {
          'ov_role::primary::install_ovdb'     => false,
          'ov_role::primary::install_postgres' => false,
        }.merge(base_config),
      )
    end
  end
end
