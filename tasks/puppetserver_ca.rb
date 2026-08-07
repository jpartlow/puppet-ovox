#! /opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require_relative "../lib/ovox/task_dispatch"
require 'open3'

# Task for interacting with the *puppetserver ca* subcommand.
class PuppetserverCA < TaskHelper
  include Ovox::TaskDispatch

  DISPATCH_MAP = {
    list: :list,
    sign: :sign,
  }.freeze

  PUPPETSERVER_CA = [
    "#{SERVER_BIN}/puppetserver",
    'ca',
  ].freeze

  # Perform a *puppetserver ca list* of just the given certnames
  # and return a subset of any signed certnames.
  #
  # @param certnames Array of certnames to lookup.
  # @return [Array[String]] Subset of certnames that have already been
  # signed.
  def lookup_signed(certnames, **kwargs)
    certs = Array(certnames)
    return [] if certs.empty?

    list_results, _s =
      list(certnames: certs, format: 'json', **kwargs)
    fail_task(list_results, **kwargs) if !list_results[:success]
    listed_hash = JSON.parse(list_results[:stdout])
    (listed_hash['signed'] || []).map { |i| i['name'] }
  end

  # Call *puppetserver ca sign*.
  def sign(certnames:, check_if_signed: true, **kwargs)
    certs = Array(certnames)

    already_signed = check_if_signed ?
      lookup_signed(certnames, **kwargs) :
      []

    certs_to_sign = certs - already_signed

    if certs_to_sign.empty?
      {
        success: true,
        certnames: certs_to_sign,
        already_signed: already_signed,
      }
    else
      cmd = PUPPETSERVER_CA + [
        'sign',
        "--certname=#{certs_to_sign.join(',')}",
      ]

      output, status = Open3.capture2e(*cmd)

      {
        command: cmd,
        output: output,
        code: status.exitstatus,
        already_signed: already_signed,
        success: status.success?,
      }
    end
  end

  # Call *puppetserver ca list*.
  def list(certnames: [], format: 'json', **kwargs)
    certs = Array(certnames)

    if certs.empty?
      {
        success: true,
        certnames: certs,
      }
    else
      cmd = PUPPETSERVER_CA + [
        'list',
        '--format=json',
        "--certname=#{certs.join(',')}",
      ]

      stdout, stderr, status = Open3.capture3(*cmd)

      {
        command: cmd,
        stdout: stdout,
        stderr: stderr,
        code: status.exitstatus,
        success: status.success?,
      }
    end
  end

  def task(command:, **kwargs)
    process(command, **kwargs)
  end
end

PuppetserverCA.run if __FILE__ == $PROGRAM_NAME
