#! /opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative "../lib/ovox/task_dispatch.rb"
require 'open3'

class PuppetAgent < TaskHelper
  include Ovox::TaskDispatch

  DISPATCH_MAP = {
    run: :run_puppet,
  }.freeze

  def run_puppet(debug: false, **_kwargs)
    cmd = [
      "#{PUPPET_BIN}/puppet",
      'agent',
      '--no-daemonize',
      '--detailed-exitcodes',
      '--onetime',
      '--no-splay',
      '--no-use_cached_catalog',
      '--no-usecacheonfailure',
    ]
    cmd << (debug ? '--debug' : '--verbose')
    output, status = Open3.capture2e(*cmd)
    results = {
      command: cmd,
      output: output,
      code: status.exitstatus,
    }
    results[:success] = [0,2].include?(status.exitstatus)
    results
  end

  def task(command:, **kwargs)
    process(command, **kwargs)
  end
end

PuppetAgent.run if __FILE__ == $PROGRAM_NAME
