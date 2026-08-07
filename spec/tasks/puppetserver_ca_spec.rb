require 'spec_helper'

require_relative '../../tasks/puppetserver_ca'
require 'json'

describe 'task: puppetserver_ca.rb' do
  let(:task) { PuppetserverCA.new }
  let(:kwargs) do
    {
      _task: 'puppetserver_ca',
      check_if_signed: check_if_signed,
      certnames: certnames,
    }
  end
  let(:check_if_signed) { true }
  let(:certnames) do
    [
      'agent1.spec',
      'agent2.spec',
    ]
  end

  let(:success) { instance_double(Process::Status, success?: true, exitstatus: 0) }
  let(:failed) { instance_double(Process::Status, success?: false, exitstatus: 1) }

  CA_CMD = [
    '/opt/puppetlabs/server/bin/puppetserver',
    'ca',
  ].freeze
  SIGN = (CA_CMD + [
    'sign',
  ]).freeze
  LIST = (CA_CMD + [
    'list',
    '--format=json',
  ]).freeze

  def command(action, certnames)
    self.class.const_get(action.to_s.upcase) +
      ["--certname=#{Array(certnames).join(',')}"]
  end

  # Simulates a subset of the JSON output of
  # *puppetserver ca list --certname*
  #
  # @param signed The certnames to output in the signed array.
  def ca_list_stdout(signed)
    {
      'signed': Array(signed).map { |i| { 'name': i } }
    }.to_json
  end

  context 'sign' do
    let(:check_if_signed) { false }

    it 'runs without testing for signed certs' do
      expect(Open3).to(
        receive(:capture2e).and_return(['output', success])
      )

      expect(task.task(command: 'sign', **kwargs)).to match(
        {
          already_signed: [],
          command: command(:sign, certnames),
          code: 0,
          output: 'output',
          success: true,
        }
      )
    end

    it 'handles a string certnames value' do
      expect(Open3).to(
        receive(:capture2e).and_return(['output', success])
      )
      kwargs[:certnames] = 'agent3.spec'

      expect(task.task(command: 'sign', **kwargs)).to match(
        {
          already_signed: [],
          command: SIGN + ['--certname=agent3.spec'],
          code: 0,
          output: 'output',
          success: true,
        }
      )
    end

    it 'raises an error if command fails' do
      expect(Open3).to(
        receive(:capture2e).and_return(['oops', failed])
      )

      expect { task.task(command: 'sign', **kwargs) }.to(
        raise_error(TaskHelper::Error, %r{oops})
      )
    end

    it 'does nothing if no targets given' do
      expect(
        task.task(command: 'sign', **(kwargs.merge({ certnames: [] })))
      ).to(
        match(
          {
            certnames: [],
            already_signed: [],
            success: true,
          }
        )
      )
    end

    context 'with a check for signed certs' do
      let(:check_if_signed) { true }

      it 'signs only unsigned certs' do
        expect(Open3).to(
          receive(:capture3).
            with(*(command(:list, certnames))).
            and_return([ca_list_stdout('agent1.spec'), '', success])
        )
        expect(Open3).to(
          receive(:capture2e).
            with(*(command(:sign, 'agent2.spec'))).
            and_return(['output', success])
        )

        expect(task.task(command: 'sign', **kwargs)).to eq(
          {
            already_signed: ['agent1.spec'],
            command: SIGN + ['--certname=agent2.spec'],
            code: 0,
            output: 'output',
            success: true,
          }
        )
      end

      it 'fails if list fails' do
        expect(Open3).to(
          receive(:capture3).
            and_return(['stdout', 'oops', failed])
        )

        expect { task.task(command: 'sign', **kwargs) }.to(
          raise_error(TaskHelper::Error, %r{oops})
        )
      end

      it 'does nothing if no targets given' do
        expect(
          task.task(command: 'sign', **(kwargs.merge({ certnames: [] })))
        ).to(
          match(
            {
              certnames: [],
              already_signed: [],
              success: true,
            }
          )
        )
      end

      it 'does not call puppetserver sign if everything already signed' do
        expect(Open3).to(
          receive(:capture3).
            with(*(command(:list, certnames))).
            and_return(
              [
                ca_list_stdout(['agent1.spec', 'agent2.spec']),
                '',
                success
              ]
            )
        )
        expect(task.task(command: 'sign', **kwargs)).to(
          match(
            {
              certnames: [],
              already_signed: ['agent1.spec', 'agent2.spec'],
              success: true,
            }
          )
        )
      end
    end
  end

  context 'list' do
    it 'returns list output' do
      stdout = ca_list_stdout(['agent2.spec'])
      expect(Open3).to(
        receive(:capture3).
          with(*(command(:list, certnames))).
          and_return([stdout, '', success])
      )

      expect(task.task(command: 'list', **kwargs)).to match(
        {
          success: true,
          command: command('list', certnames),
          stderr: '',
          stdout: stdout,
          code: 0
        }
      )
    end

    it 'does nothing if given empty certnames' do
      expect(
        task.task(command: 'list', **(kwargs.merge({ certnames: [] })))
      ).to match(
        {
          success: true,
          certnames: [],
        }
      )
    end
  end

  context 'lookup_signed' do
    it 'returns an empty array if given empty certnames' do
      expect(task.lookup_signed([], **kwargs)).to match(
        []
      )
    end

    it 'returns any certnames that are already signed' do
      expect(Open3).to(
        receive(:capture3).
          with(*(command(:list, certnames))).
          and_return(
            [
              ca_list_stdout(['agent1.spec', 'agent2.spec']),
              '',
              success
            ]
          )
      )

      expect(task.lookup_signed(certnames, **kwargs)).to match(
        ['agent1.spec', 'agent2.spec']
      )
    end

    it 'returns an empty array if none of the certnames are signed' do
      expect(Open3).to(
        receive(:capture3).
          with(*(command(:list, certnames))).
          and_return([ ca_list_stdout([]), '', success ])
      )

      expect(task.lookup_signed(certnames, **kwargs)).to match(
        []
      )
    end

    it 'returns an empty array if the list output does not have a signed element' do
      expect(Open3).to(
        receive(:capture3).
          with(*(command(:list, certnames))).
          and_return(['{}', '', success ])
      )

      expect(task.lookup_signed(certnames, **kwargs)).to match(
        []
      )
    end
  end
end
