require 'spec_helper'

require_relative '../../tasks/puppetdb'

describe 'task: ovox::puppetdb.rb' do
  let(:task) { Ovox::PuppetDB.new }
  let(:kwargs) do
    {
      _task: 'puppetdb',
    }
  end

  let(:success) { instance_double(Process::Status, success?: true, exitstatus: 0) }
  let(:failed) { instance_double(Process::Status, success?: false, exitstatus: 1) }

  context 'ssl-setup' do
    it 'runs and returns successful result' do
      expect(Open3).to(
        receive(:capture2e).and_return(['output', success])
      )

      expect(task.task(command: 'ssl-setup', **kwargs)).to eq(
        {
          command: ['/opt/puppetlabs/server/bin/puppetdb', 'ssl-setup'],
          output: 'output',
          code: 0,
          success: true,
        }
      )
    end

    it 'raises if fails' do
      expect(Open3).to(
        receive(:capture2e).and_return(['oops', failed])
      )

      expect { task.task(command: 'ssl-setup', **kwargs) }.to(
        raise_error(TaskHelper::Error, %r{oops})
      )
    end
  end
end
