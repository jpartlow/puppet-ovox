# Generate and sign openvox agent certificates for the given
# targets.
#
# This plan is idempotent.
#
# The only side effect is that the primary openvox-server will always
# be left in a running state since it must be up to receive csrs and
# sign.
#
# @param primary The openvoxserver CA node.
# @param targets The nodes to generate and sign certs for.
plan ovox::subplans::certs (
  Target        $primary,
  Array[Target] $targets,
)  {
  # Stand up CA
  apply($primary) {
    service { 'puppetserver':
      ensure => 'running',
    }
  }
  # check status endpoint?

  # Generate and submit certificates.
  run_task('ovox::puppet_ssl', $targets,
    'command' => 'generate',
  )

  # Sign certificates.
  if $targets.length > 0 {
    run_task('ovox::puppetserver_ca', $primary,
      'command'   => 'sign',
      'certnames' => $targets.map |$t| { $t.name },
    )
  } else {
    out::message('No targets, nothing to sign.')
  }
}
