#! /opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative "../lib/ovox/task_dispatch"
require 'open3'

# Task for interacting with the *puppetserver ca* subcommand.
module Ovox
  class PuppetDB < TaskHelper
    include Ovox::TaskDispatch

    DISPATCH_MAP = {
       'ssl-setup': :ssl_setup
    }.freeze

    def ssl_setup(**_kwargs)
      cmd = [
        "#{SERVER_BIN}/puppetdb",
        'ssl-setup',
      ]

      output, status = Open3.capture2e(*cmd)

      {
        command: cmd,
        output: output,
        code: status.exitstatus,
        success: status.success?
      }
    end

    def task(command:, **kwargs)
      process(command, **kwargs)
    end
  end
end

Ovox::PuppetDB.run if __FILE__ == $PROGRAM_NAME
