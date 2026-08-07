# frozen_string_literal: true

require 'spec_helper'

require 'ovox/task_dispatch'

describe Ovox::TaskDispatch do
  class Tester
    include Ovox::TaskDispatch

    DISPATCH_MAP = {
      foo:       :foobar,
      fails:     :oops,
      malformed: :malformed,
      nosuccess: :nosuccess,
    }.freeze

    def foobar(**kwargs)
      {
        command: ['ran', '--something'],
        code: 0,
        success: true,
        output: 'output',
      }
    end

    def oops(**kwargs)
      {
        command: ['ran', '--but-failed'],
        code: 1,
        success: false,
        output: 'oops',
      }
    end

    def malformed(**kwargs)
      ['bad', 'results']
    end

    def nosuccess(**kwargs)
      {
        command: ['ran', '--successfully'],
        code: 0,
        output: 'output',
      }
    end
  end

  let(:tester) { Tester.new }
  let(:kwargs) { { _task: 'spec' } }

  context '#dispatch' do
    it 'dispatches a mapped command' do
      expect(tester.dispatch('foo', **kwargs)).to match(
        {
          code: 0,
          command: ['ran', '--something'],
          output: 'output',
          success: true,
        }
      )
    end

    it 'raises an error if command is unmapped' do
      expect { tester.dispatch('unmapped', **kwargs) }.to(
        raise_error(
          TaskHelper::Error,
          "Unimplemented subcommand 'unmapped'. Expected one of [:foo, :fails, :malformed, :nosuccess]."
        )
      )
    end
  end

  context '#fail_task' do
    let(:results) { tester.oops }

    it 'raises an error' do
      expect { tester.fail_task(results, **kwargs) }.to(
        raise_error(TaskHelper::Error) do |e|
          expect(e.message).to eq(<<~MSG.strip)
            Task: 'spec'
            Command: 'ran --but-failed'
            Exitcode: '1'
            Output:
            oops
          MSG
          expect(e.kind).to eq('spec/failed')
          expect(e.details).to eq(results)
        end
      )
    end

    it 'raises an error without a command' do
      r = results.except(:command)
      expect { tester.fail_task(r, **kwargs) }.to(
        raise_error(TaskHelper::Error) do |e|
          expect(e.message).to eq(<<~MSG.strip)
            Task: 'spec'
            Command: '(no-command-given)'
            Exitcode: '1'
            Output:
            oops
          MSG
        end
      )
    end

    it 'handles results with stdout/stderr' do
      r = {
        command: ['ran', '--but-failed'],
        code: 1,
        success: false,
        stdout: 'stdout',
        stderr: 'stderr',
      }
      expect { tester.fail_task(r, **kwargs) }.to(
        raise_error(TaskHelper::Error) do |e|
          expect(e.message).to eq(<<~MSG.strip)
            Task: 'spec'
            Command: 'ran --but-failed'
            Exitcode: '1'
            Stderr:
            stderr
            Stdout:
            stdout
          MSG
        end
      )
    end
  end

  context '#process' do
    it 'dispatches and returns successful output' do
      expect(tester.process('foo', **kwargs)).to eq(tester.foobar)
    end

    it 'dispatches and runs fail_task when unsuccessful' do
      expect { tester.process('fails', **kwargs) }.to(
        raise_error(TaskHelper::Error, %r{.*Command: 'ran --but-failed'.*}m)
      )
    end

    it 'fails if dispatch method returns non-hash' do
      expect { tester.process('malformed', **kwargs) }.to(
        raise_error(TaskHelper::Error) do |e|
          expect(e.message).to eq(<<~MSG.strip)
            Task: 'spec'
            Command: 'malformed'
            Exitcode: ''
          MSG
          expect(e.kind).to eq('spec/internal')
          expect(e.details).to eq(
            {
              command: 'malformed',
              internal_error:
                '(dispatched-command-returned-non-hash-results)',
              results: ['bad', 'results'],
            }
          )
        end
      )
    end

    it 'fails and warns if no success key' do
      expect { tester.process('nosuccess', **kwargs) }.to(
        raise_error(TaskHelper::Error) do |e|
          expect(e.message).to eq(<<~MSG.strip)
            Task: 'spec'
            Command: 'ran --successfully'
            Exitcode: '0'
            Output:
            output
          MSG
          expect(e.kind).to eq('spec/failed')
          expect(e.details).to eq(
            {
              command: ['ran', '--successfully'],
              code: 0,
              output: 'output',
              internal_error:
                '(no-success-field-included-in-dispatch-results)',
            }
          )
        end
      )
    end
  end
end
