require 'spec_helper'
require 'tmpdir'

describe 'plan: ovox::subplans::configure' do
  include_context 'plan_init'
  include_context('shared target maps')

  around(:each) do |example|
    # The plan would do this, if the run_command weren't stubbed.
    FileUtils.mkdir_p(cluster_hiera_dir)
    example.run
  ensure
    FileUtils.remove_entry_secure(tempdir)
  end

  let(:tempdir) { Dir.mktmpdir('rspec-ovox-configure') }
  let(:cluster_id) { 'spec' }
  let(:params) do
    {
      'cluster_id'     => cluster_id,
      'target_map'     => target_map,
      'hiera_data_dir' => tempdir,
    }
  end
  let(:cluster_hiera_dir) { "#{tempdir}/cluster/#{cluster_id}" }

  def configure_params(server, role = nil)
    params = {
      'puppet_conf' => {
        'main' => {
          'server' => server.host(),
        }
      },
      'puppet_service_running' => false,
      'puppet_service_enabled' => true,
    }
    params.merge!(
      {
        'csr_attributes' => {
          'extension_requests' => {
            'pp_role' => role,
          }
        }
      }
    ) if !role.nil?

    params
  end

  context 'small' do
    let(:target_map) { s_target_map }

    it 'runs for a small arch' do
      expect_task('openvox_bootstrap::configure').
        with_targets([primary]).
        with_params(configure_params(primary, 'primary'))
      allow_out_message
      expect_command("mkdir #{cluster_hiera_dir}").
        with_targets('localhost')
      allow_apply
      expect_task('openvox_bootstrap::configure').
        with_targets([agent]).
        with_params(configure_params(primary))
      expect_task('ovox::run_agent').
        with_targets([primary, agent])
      expect_task('openvox_bootstrap::configure').
        with_targets([primary, agent]).
        with_params(
          {
            'puppet_service_running' => true,
            'puppet_service_enabled' => true,
          }
        )

      result = run_plan('ovox::subplans::configure', params)
      expect(result.ok?).to(eq(true), result.value.to_s)

      cluster_hiera = YAML.safe_load_file("#{cluster_hiera_dir}/common.yaml")
      expect(cluster_hiera).to match(
        {
          'ov_role::primary::install_ovdb'     => true,
          'ov_role::primary::install_postgres' => true,
        }
      )
    end
  end

  context 'huge' do
    let(:target_map) { h_target_map }
    let(:all_targets) do
      [
        primary,
        ovdb1,
        ovdb2,
        postgres,
        compiler1,
        compiler2,
        clb,
        ovdblb,
        agent,
      ]
    end

    it 'runs for a huge arch' do
      expect_task('openvox_bootstrap::configure').
        with_targets([primary]).
        with_params(configure_params(primary, 'primary'))
      expect_task('openvox_bootstrap::configure').
        with_targets([ovdb1]).
        with_params(configure_params(primary, 'ovdb'))
      expect_task('openvox_bootstrap::configure').
        with_targets([ovdb2]).
        with_params(configure_params(primary, 'ovdb'))
      expect_task('openvox_bootstrap::configure').
        with_targets([compiler1]).
        with_params(configure_params(primary, 'compiler'))
      expect_task('openvox_bootstrap::configure').
        with_targets([compiler2]).
        with_params(configure_params(primary, 'compiler'))
      expect_task('openvox_bootstrap::configure').
        with_targets([postgres]).
        with_params(configure_params(primary, 'postgres'))
      expect_task('openvox_bootstrap::configure').
        with_targets([clb]).
        with_params(configure_params(primary, 'compiler_lb'))
      expect_task('openvox_bootstrap::configure').
        with_targets([ovdblb]).
        with_params(configure_params(primary, 'ovdb_lb'))
      allow_out_message
      expect_command("mkdir #{cluster_hiera_dir}").
        with_targets('localhost')
      allow_apply
      expect_task('openvox_bootstrap::configure').
        with_targets([agent]).
        with_params(configure_params(primary))
      expect_task('ovox::run_agent').
        with_targets(all_targets)
      expect_task('openvox_bootstrap::configure').
        with_targets(all_targets).
        with_params(
          {
            'puppet_service_running' => true,
            'puppet_service_enabled' => true,
          }
        )

      result = run_plan('ovox::subplans::configure', params)
      expect(result.ok?).to(eq(true), result.value.to_s)

      cluster_hiera = YAML.safe_load_file("#{cluster_hiera_dir}/common.yaml")
      expect(cluster_hiera).to match(
        {
          'ov_role::primary::install_ovdb'     => false,
          'ov_role::primary::install_postgres' => false,
          'ov_role::ovdb::install_postgres'    => false,
        }
      )
    end
  end
end
