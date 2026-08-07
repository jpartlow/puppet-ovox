require 'spec_helper'

require_relative '../../tasks/puppet_ssl'

describe 'task: puppet_ssl.rb' do
  let(:task) { PuppetSSL.new }
  let(:allow_existing_csr) { true }
  let(:kwargs) do
    {
      _task: 'puppet_ssl',
      allow_existing_csr: allow_existing_csr,
    }
  end

  let(:success) { instance_double(Process::Status, success?: true, exitstatus: 0) }
  let(:failed) { instance_double(Process::Status, success?: false, exitstatus: 1) }
  let(:submit_request) do
    [
      '/opt/puppetlabs/bin/puppet',
      'ssl',
      'submit_request',
    ]
  end

  context 'generate' do
    let(:csr_submitted_err) do
      <<~ERR
        Error: Could not run: Could not submit certificate request \
        for 'agent.spec' to https://primary.spec:8140/puppet-ca/v1 \
        due to a conflict on the server
      ERR
    end

    it 'runs and returns successful result' do
      expect(Open3).to(
        receive(:capture2e).and_return(['output', success])
      )

      expect(task.task(command: 'generate', **kwargs)).to eq(
        {
          command: submit_request,
          output: 'output',
          code: 0,
          success: true,
        }
      )
    end

    it 'returns success if allow_existing_csr and csr submitted already'do
      expect(Open3).to(
        receive(:capture2e).and_return([csr_submitted_err, failed])
      )

      expect(task.task(command: 'generate', **kwargs)).to eq(
        {
          command: submit_request,
          output: csr_submitted_err,
          code: 1,
          success: true,
        }
      )
    end

    it 'raises if fails' do
      expect(Open3).to(
        receive(:capture2e).and_return(['oops', failed])
      )

      expect { task.task(command: 'generate', **kwargs) }.to(
        raise_error(TaskHelper::Error, %r{oops})
      )
    end

    it 'raises if csr submitted and allow_existing_csr is false' do
      expect(Open3).to(
        receive(:capture2e).and_return([csr_submitted_err, failed])
      )
      kwargs[:allow_existing_csr] = false

      expect { task.task(command: 'generate', **kwargs) }.to(
        raise_error(
          TaskHelper::Error,
          %r{Could not submit certificate request.*due to a conflict on the server}
        )
      )
    end
  end
end
