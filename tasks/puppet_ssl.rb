#! /opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative "../lib/ovox/task_dispatch"
require 'open3'

class PuppetSSL < TaskHelper
  include Ovox::TaskDispatch

  DISPATCH_MAP = {
    generate: :generate_and_submit_csr,
  }.freeze

  PUPPET_SSL_CSR_SUBMITTED_ERROR = %r{Could not submit certificate request for .*/puppet-ca/v1 due to a conflict on the server}

  def generate_and_submit_csr(allow_existing_csr: true, **kwargs)
    cmd = [
      "#{PUPPET_BIN}/puppet",
      'ssl',
      'submit_request',
    ]
    output, status = Open3.capture2e(*cmd)
    results = {
      command: cmd,
      output: output,
      code: status.exitstatus,
    }
    already_submitted =
      output.match?(PUPPET_SSL_CSR_SUBMITTED_ERROR)
    results[:success] =
      status.success? || (allow_existing_csr && already_submitted)

    results
  end

  def task(command:, **kwargs)
    process(command, **kwargs)
  end
end

PuppetSSL.run if __FILE__ == $PROGRAM_NAME
