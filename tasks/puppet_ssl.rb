#! /opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative "../lib/ovox/task_dispatch"
require 'open3'

class PuppetSSL < TaskHelper
  include Ovox::TaskDispatch

  DISPATCH_MAP = {
    generate: :generate_and_submit_csr,
    download: :download_cert,
  }.freeze

  PUPPET_SSL_CSR_SUBMITTED_ERROR = %r{Could not submit certificate request for .*/puppet-ca/v1 due to a conflict on the server}

  def ssl_command(command, &postproc)
    cmd = [
      "#{PUPPET_BIN}/puppet",
      'ssl',
      command.to_s,
    ]
    output, status = Open3.capture2e(*cmd)
    results = {
      command: cmd,
      output: output,
      code: status.exitstatus,
    }
    if block_given?
      yield(output, status, results)
    else
      results[:success] = status.success?
    end
    results
  end

  def generate_and_submit_csr(allow_existing_csr: true, **kwargs)
    results = ssl_command(:submit_request) do |o, s, r|
      already_submitted =
        o.match?(PUPPET_SSL_CSR_SUBMITTED_ERROR)
      r[:success] = s.success? || (allow_existing_csr && already_submitted)
    end

    results
  end

  def download_cert(**_kwargs)
    ssl_command(:download_cert)
  end

  def task(command:, **kwargs)
    process(command, **kwargs)
  end
end

PuppetSSL.run if __FILE__ == $PROGRAM_NAME
