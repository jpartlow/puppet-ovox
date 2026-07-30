require 'spec_helper'

describe 'plan: ovox::subplans::install_openvox' do
  include_context 'plan_init'
  include_context('shared target maps')

  let(:all_targets) { [ agent ] }
  let(:params) do
    {
      'target_map' => just_agents_target_map,
    }
  end

  before(:each) do
    allow_out_message
    expect_plan('facts')
      .with_params('targets' => all_targets)
  end

  it 'installs latest agent on targets' do
    expect_task('openvox_bootstrap::install')
      .with_targets(all_targets)
      .with_params({
        'package'    => 'openvox-agent',
        'version'    => 'latest',
        'collection' => 'openvox8',
        'apt_source' => 'https://apt.voxpupuli.org',
        'yum_source' => 'https://yum.voxpupuli.org',
        'stop_service' => false,
        '_catch_errors' => true,
      })
    expect_task('package')
      .with_targets(all_targets)
      .always_return({
        'status' => 'installed',
        'version' => '8.0.0',
      })

    result = run_plan('ovox::subplans::install_openvox', params)
    expect(result.ok?).to(eq(true), result.value.to_s)

    version_map = result.value
    expect(version_map).to eq({
      'agent.spec' => {
        'openvox-agent' => '8.0.0',
      }
    })
  end

  it 'installs specific agent on targets' do
    params['openvox_agent_params'] = {
      'openvox_version'  => '7.0.0',
    }

    expect_task('openvox_bootstrap::install')
      .with_targets(all_targets)
      .with_params({
        'package'    => 'openvox-agent',
        'version'    => '7.0.0',
        'collection' => 'openvox7',
        'apt_source' => 'https://apt.voxpupuli.org',
        'yum_source' => 'https://yum.voxpupuli.org',
        'stop_service' => false,
        '_catch_errors' => true,
      })
    expect_task('package')

    result = run_plan('ovox::subplans::install_openvox', params)
    expect(result.ok?).to(eq(true), result.value.to_s)
  end

  it 'installs a pre-release build on targets' do
    params['openvox_agent_params'] = {
      'openvox_version'  => '9.0.0',
      'openvox_released' => false,
    }

    expect_task('openvox_bootstrap::install_build_artifact')
      .with_targets(all_targets)
      .with_params({
        'version'    => '9.0.0',
        'package'    => 'openvox-agent',
        'artifacts_source' => 'https://artifacts.voxpupuli.org',
        '_catch_errors' => true,
      })
    expect_task('package')

    result = run_plan('ovox::subplans::install_openvox', params)
    expect(result.ok?).to(eq(true), result.value.to_s)
  end

  it 'installs from a different artifacts_source' do
    params['openvox_agent_params'] = {
      'openvox_version' => '9.0.0',
      'openvox_released' => false,
      'openvox_artifacts_url' => 'https://some.other',
    }

    expect_task('openvox_bootstrap::install_build_artifact')
      .with_targets(all_targets)
      .with_params({
        'version'    => '9.0.0',
        'package'    => 'openvox-agent',
        'artifacts_source' => 'https://some.other',
        '_catch_errors' => true,
      })
    expect_task('package')

    result = run_plan('ovox::subplans::install_openvox', params)
    expect(result.ok?).to(eq(true), result.value.to_s)
  end

  context 'with primary targets' do
    let(:agent_targets) { [ agent ] }
    let(:primary_targets) { [ primary ] }
    let(:all_targets) { primary_targets + agent_targets }
    let(:params) do
      {
        'target_map' => s_target_map,
      }
    end

    it 'installs latest agent and all server packages to targets' do
      expect_task('openvox_bootstrap::install')
        .with_targets(all_targets)
        .with_params({
          'package'    => 'openvox-agent',
          'version'    => 'latest',
          'collection' => 'openvox8',
          'apt_source' => 'https://apt.voxpupuli.org',
          'yum_source' => 'https://yum.voxpupuli.org',
          'stop_service' => false,
          '_catch_errors' => true,
        })
      expect_task('openvox_bootstrap::install')
        .with_targets(primary_targets)
        .with_params({
          'package'    => 'openvox-server',
          'version'    => 'latest',
          'collection' => 'openvox8',
          'apt_source' => 'https://apt.voxpupuli.org',
          'yum_source' => 'https://yum.voxpupuli.org',
          'stop_service' => false,
          '_catch_errors' => true,
        })
      expect_task('openvox_bootstrap::install')
        .with_targets(primary_targets)
        .with_params({
          'package'    => 'openvoxdb',
          'version'    => 'latest',
          'collection' => 'openvox8',
          'apt_source' => 'https://apt.voxpupuli.org',
          'yum_source' => 'https://yum.voxpupuli.org',
          'stop_service' => false,
          '_catch_errors' => true,
        })
      expect_task('openvox_bootstrap::install')
        .with_targets(primary_targets)
        .with_params({
          'package'    => 'openvoxdb-termini',
          'version'    => 'latest',
          'collection' => 'openvox8',
          'apt_source' => 'https://apt.voxpupuli.org',
          'yum_source' => 'https://yum.voxpupuli.org',
          'stop_service' => false,
          '_catch_errors' => true,
        })
      expect_task('package')
        .with_targets(all_targets)
        .always_return({
          'status' => 'installed',
          'version' => '8.0.0',
        })
      expect_task('package')
        .with_targets(primary_targets)
        .with_params({
          'name'   => 'openvox-server',
          'action' => 'status',
        })
        .always_return({
          'status' => 'installed',
          'version' => '8.1.0',
        })
      expect_task('package')
        .with_targets(primary_targets)
        .with_params({
          'name'   => 'openvoxdb',
          'action' => 'status',
        })
        .always_return({
          'status' => 'installed',
          'version' => '8.2.0',
        })
      expect_task('package')
        .with_targets(primary_targets)
        .with_params({
          'name'   => 'openvoxdb-termini',
          'action' => 'status',
        })
        .always_return({
          'status' => 'installed',
          'version' => '8.2.1',
        })

      result = run_plan('ovox::subplans::install_openvox', params)
      expect(result.ok?).to(eq(true), result.value.to_s)

      version_map = result.value
      expect(version_map).to eq({
        'agent.spec' => {
          'openvox-agent' => '8.0.0',
        },
        'primary.spec' => {
          'openvox-agent'     => '8.0.0',
          'openvox-server'    => '8.1.0',
          'openvoxdb'         => '8.2.0',
          'openvoxdb-termini' => '8.2.1',
        }
      })
    end

    it 'installs specific server packages to targets' do
      params['openvox_server_params'] = {
        'openvox_version'  => '9.0.0',
        'openvox_released' => false,
      }

      expect_task('openvox_bootstrap::install')
        .with_targets(all_targets)
        .with_params({
          'package'    => 'openvox-agent',
          'version'    => 'latest',
          'collection' => 'openvox8',
          'apt_source' => 'https://apt.voxpupuli.org',
          'yum_source' => 'https://yum.voxpupuli.org',
          'stop_service' => false,
          '_catch_errors' => true,
        })
      allow_apply
      expect_task('openvox_bootstrap::install_build_artifact')
        .with_targets(primary_targets)
        .with_params({
          'package'    => 'openvox-server',
          'version'    => '9.0.0',
          'artifacts_source' => 'https://artifacts.voxpupuli.org',
          '_catch_errors' => true,
        })
      expect_task('openvox_bootstrap::install')
        .with_targets(primary_targets)
        .with_params({
          'package'    => 'openvoxdb',
          'version'    => 'latest',
          'collection' => 'openvox8',
          'apt_source' => 'https://apt.voxpupuli.org',
          'yum_source' => 'https://yum.voxpupuli.org',
          'stop_service' => false,
          '_catch_errors' => true,
        })
      expect_task('openvox_bootstrap::install')
        .with_targets(primary_targets)
        .with_params({
          'package'    => 'openvoxdb-termini',
          'version'    => 'latest',
          'collection' => 'openvox8',
          'apt_source' => 'https://apt.voxpupuli.org',
          'yum_source' => 'https://yum.voxpupuli.org',
          'stop_service' => false,
          '_catch_errors' => true,
        })
      expect_task('package').be_called_times(4)

      result = run_plan('ovox::subplans::install_openvox', params)
      expect(result.ok?).to(eq(true), result.value.to_s)
    end

    context 'with agent and server targets' do
      let(:params) do
        {
          'target_map' => t_target_map,
          'openvox_server_params' => {
            'openvox_version'  => '8.1.0',
          },
          'openvox_db_params' => {
            'openvox_version'  => '8.2.0',
          },
        }
      end

      it 'installs latest agent, openvox-server and openvoxdb-termini packages' do
        expect_task('openvox_bootstrap::install')
          .with_targets(all_targets)
          .with_params({
            'package'    => 'openvox-agent',
            'version'    => 'latest',
            'collection' => 'openvox8',
            'apt_source' => 'https://apt.voxpupuli.org',
            'yum_source' => 'https://yum.voxpupuli.org',
            'stop_service' => false,
            '_catch_errors' => true,
          })
        expect_task('openvox_bootstrap::install')
          .with_targets(primary_targets)
          .with_params({
            'package'    => 'openvox-server',
            'version'    => '8.1.0',
            'collection' => 'openvox8',
            'apt_source' => 'https://apt.voxpupuli.org',
            'yum_source' => 'https://yum.voxpupuli.org',
            'stop_service' => false,
            '_catch_errors' => true,
          })
        expect_task('openvox_bootstrap::install')
          .with_targets(primary_targets)
          .with_params({
            'package'    => 'openvoxdb-termini',
            'version'    => '8.2.0',
            'collection' => 'openvox8',
            'apt_source' => 'https://apt.voxpupuli.org',
            'yum_source' => 'https://yum.voxpupuli.org',
            'stop_service' => false,
            '_catch_errors' => true,
          })
        expect_task('package').be_called_times(3)
          .always_return({
            'status' => 'installed',
            'version' => 'v',
          })

        result = run_plan('ovox::subplans::install_openvox', params)
        expect(result.ok?).to(eq(true), result.value.to_s)

        version_map = result.value
        expect(version_map).to eq({
          'agent.spec' => {
            'openvox-agent' => 'v',
          },
          'primary.spec' => {
            'openvox-agent'     => 'v',
            'openvox-server'    => 'v',
            'openvoxdb-termini' => 'v',
          }
        })
      end

      it 'skips openvoxdb-termini installation' do
        params['install_termini'] = false

        expect_task('openvox_bootstrap::install')
          .with_targets(all_targets)
          .with_params({
            'package'    => 'openvox-agent',
            'version'    => 'latest',
            'collection' => 'openvox8',
            'apt_source' => 'https://apt.voxpupuli.org',
            'yum_source' => 'https://yum.voxpupuli.org',
            'stop_service' => false,
            '_catch_errors' => true,
          })
        expect_task('openvox_bootstrap::install')
          .with_targets(primary_targets)
          .with_params({
            'package'    => 'openvox-server',
            'version'    => '8.1.0',
            'collection' => 'openvox8',
            'apt_source' => 'https://apt.voxpupuli.org',
            'yum_source' => 'https://yum.voxpupuli.org',
            'stop_service' => false,
            '_catch_errors' => true,
          })
        expect_task('package').be_called_times(2)
          .always_return({
            'status' => 'installed',
            'version' => 'v',
          })

        result = run_plan('ovox::subplans::install_openvox', params)
        expect(result.ok?).to(eq(true), result.value.to_s)
      end
    end

    context 'for a huge arch with different server and db targets' do
      let(:primary_targets) { [ primary ] }
      let(:compiler_targets) { [ compiler1, compiler2 ] }
      let(:db_targets) { [ ovdb1, ovdb2 ] }
      # This is unfortunately order dependent because
      # expect_plan.with_params() is going to match the target array
      # exactly...
      let(:all_targets) do
        primary_targets +
          db_targets +
          compiler_targets +
          agent_targets +
          [
            postgres,
            clb,
            ovdblb,
          ]
      end
      let(:params) do
        {
          'target_map' => h_target_map,
          'openvox_server_params' => {
            'openvox_version'  => '8.1.0',
          },
        }
      end

      it 'installs to all targets' do
        expect_task('openvox_bootstrap::install')
          .with_targets(all_targets)
          .with_params({
            'package'    => 'openvox-agent',
            'version'    => 'latest',
            'collection' => 'openvox8',
            'apt_source' => 'https://apt.voxpupuli.org',
            'yum_source' => 'https://yum.voxpupuli.org',
            'stop_service' => false,
            '_catch_errors' => true,
          })
        expect_task('openvox_bootstrap::install')
          .with_targets(primary_targets)
          .with_params({
            'package'    => 'openvox-server',
            'version'    => '8.1.0',
            'collection' => 'openvox8',
            'apt_source' => 'https://apt.voxpupuli.org',
            'yum_source' => 'https://yum.voxpupuli.org',
            'stop_service' => false,
            '_catch_errors' => true,
          })
        expect_task('openvox_bootstrap::install')
          .with_targets(compiler_targets)
          .with_params({
            'package'    => 'openvox-server',
            'version'    => 'latest',
            'collection' => 'openvox8',
            'apt_source' => 'https://apt.voxpupuli.org',
            'yum_source' => 'https://yum.voxpupuli.org',
            'stop_service' => false,
            '_catch_errors' => true,
          })
        expect_task('openvox_bootstrap::install')
          .with_targets(db_targets)
          .with_params({
            'package'    => 'openvoxdb',
            'version'    => 'latest',
            'collection' => 'openvox8',
            'apt_source' => 'https://apt.voxpupuli.org',
            'yum_source' => 'https://yum.voxpupuli.org',
            'stop_service' => false,
            '_catch_errors' => true,
          })
        expect_task('openvox_bootstrap::install')
          .with_targets(primary_targets + compiler_targets)
          .with_params({
            'package'    => 'openvoxdb-termini',
            'version'    => 'latest',
            'collection' => 'openvox8',
            'apt_source' => 'https://apt.voxpupuli.org',
            'yum_source' => 'https://yum.voxpupuli.org',
            'stop_service' => false,
            '_catch_errors' => true,
          })
        expect_task('package').be_called_times(5)
          .always_return({
            'status' => 'installed',
            'version' => 'v',
          })

        result = run_plan('ovox::subplans::install_openvox', params)
        expect(result.ok?).to(eq(true), result.value.to_s)

        version_map = result.value
        expect(version_map).to eq({
          'agent.spec' => {
            'openvox-agent' => 'v',
          },
          'primary.spec' => {
            'openvox-agent'     => 'v',
            'openvox-server'    => 'v',
            'openvoxdb-termini' => 'v',
          },
          'ovdb1.spec' => {
            'openvox-agent' => 'v',
            'openvoxdb'     => 'v',
          },
          'ovdb2.spec' => {
            'openvox-agent' => 'v',
            'openvoxdb'     => 'v',
          },
          'compiler1.spec' => {
            'openvox-agent'     => 'v',
            'openvox-server'    => 'v',
            'openvoxdb-termini' => 'v',
          },
          'compiler2.spec' => {
            'openvox-agent'     => 'v',
            'openvox-server'    => 'v',
            'openvoxdb-termini' => 'v',
          },
          'postgres.spec' => {
            'openvox-agent' => 'v',
          },
          'clb.spec' => {
            'openvox-agent' => 'v',
          },
          'ovdblb.spec' => {
            'openvox-agent' => 'v',
          },
        })
      end
    end
  end
end
