# frozen_string_literal: true

require_relative "../../../ruby_task_helper/files/task_helper.rb"

module Ovox
  # Mixin providing subcommand dispatching tools for a common set
  # of ovox tasks.
  #
  # Including class must setup a DISPATCH_MAP constant mapping
  # commands to methods.
  #
  # Dispatched methods must return a results hash that includes a
  # :success boolean.
  #
  # Tasks should hand off to the dispatcher by calling process().
  module TaskDispatch
    PUPPET_BIN = '/opt/puppetlabs/bin'
    SERVER_BIN = '/opt/puppetlabs/server/bin'

    def dispatch_map
      self.class::DISPATCH_MAP
    end

    def dispatch(command, **kwargs)
      method = dispatch_map[command.to_sym]
      raise(
        TaskHelper::Error.new(
          "Unimplemented subcommand '#{command}'. Expected one of #{dispatch_map.keys}.",
          "#{kwargs['_task']}/unimplemented",
        )
      ) if method.nil?
      send(method, **kwargs)
    end

    def fail_task(results, kind = 'failed', _task:, **kwargs)
      command = case results[:command]
                when Array
                  results[:command].join(' ')
                when nil
                  '(no-command-given)'
                else
                  results[:command]
                end

      msg = <<~ERR
        Task: '#{_task}'
        Command: '#{command}'
        Exitcode: '#{results[:code]}'
      ERR
      [
        :output,
        :stderr,
        :stdout,
      ].each do |key|
        if results.include?(key)
          msg << <<~OUT
            #{key.to_s.capitalize}:
            #{results[key]}
          OUT
        end
      end

      raise(
        TaskHelper::Error.new(
          msg.strip,
          "#{_task}/#{kind}",
          results
        )
      )
    end

    # Calls dispatch() on behalf of the task and returns the given
    # results.
    #
    # @param command The subcommand string to dispatch on.
    # @param kwargs The rest of the task's keyword arguments.
    # @raise TaskHelper::Error When returned results Hash does not
    #   include a :success key that is true.
    def process(command, **kwargs)
      results = dispatch(command, **kwargs)
      if !results.kind_of?(Hash)
        err_results = {
          command: command,
          results: results,
          internal_error: '(dispatched-command-returned-non-hash-results)',
        }
        fail_task(err_results, 'internal', **kwargs)
      elsif !results.include?(:success)
        results[:internal_error] =
          '(no-success-field-included-in-dispatch-results)'
      end
      fail_task(results, **kwargs) if !results[:success]
      results
    end
  end
end
