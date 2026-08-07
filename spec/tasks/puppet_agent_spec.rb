require 'spec_helper'

require_relative '../../tasks/puppet_agent'

describe 'task: puppet_agent.rb' do
  let(:task) { PuppetAgent.new }
  let(:kwargs) { { _task: 'puppet_agent' } }
  let(:cmd_run) do
    [
      '/opt/puppetlabs/bin/puppet',
      'agent',
      '--no-daemonize',
      '--detailed-exitcodes',
      '--onetime',
      '--no-splay',
      '--no-use_cached_catalog',
      '--no-usecacheonfailure',
      '--verbose',
    ]
  end
  let(:cmd_run_debug) do
    cmd_run.reject { |i| i == '--verbose' }.append('--debug')
  end

  let(:success_no_change) { instance_double(Process::Status, success?: true, exitstatus: 0) }
  let(:success_changes) { instance_double(Process::Status, success?: true, exitstatus: 2) }
  let(:failed) { instance_double(Process::Status, success?: false, exitstatus: 1) }

  it 'runs successfully with no changes' do
    expect(Open3).to receive(:capture2e).and_return(['logs', success_no_change])

    expect(task.task(command: 'run', **kwargs)).to eq(
      {
        command: cmd_run,
        code: 0,
        output: 'logs',
        success: true,
      }
    )
  end

  it 'runs successfully with changes' do
    expect(Open3).to receive(:capture2e).and_return(['logs', success_changes])

    expect(task.task(command: 'run', **kwargs)).to eq(
      {
        command: cmd_run,
        code: 2,
        output: 'logs',
        success: true,
      }
    )
  end

  it 'runs with --debug' do
    expect(Open3).to receive(:capture2e).and_return(['logs', success_no_change])

    kwargs[:debug] = true
    expect(task.task(command: 'run', **kwargs)).to eq(
      {
        command: cmd_run_debug,
        code: 0,
        output: 'logs',
        success: true,
      }
    )
  end

  it 'fails for other exit codes' do
    expect(Open3).to receive(:capture2e).and_return(['logs', failed])

    expect { task.task(command: 'run', **kwargs) }.to raise_error(TaskHelper::Error)
  end
end
