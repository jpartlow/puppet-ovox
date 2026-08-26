# Generate and sign openvox agent certificates for the given
# targets.
#
# This plan is idempotent.
#
# The only side effect is that the primary openvox-server will always
# be left in a running state since it must be up to receive csrs and
# sign.
#
# This plan will also ensure that the *puppetdb ssl-setup* command is
# run after agent certs are generated if it is given a set of
# $ovdb_targets.
#
# Note: the openvoxdb package magically runs 'puppetdb ssl-setup' as
# part of its post-install steps, but if the package has been
# installed prior to puppet certs being generated (as is the case with
# the ovox::subplans::install_openvox plan...), this doesn't help.
#
# @param primary The openvoxserver CA node.
# @param targets The nodes to generate and sign certs for.
# @param ovdb_targets Any openvoxdb targets that additionally need to
#   run *puppetdb ssl-setup*.
plan ovox::subplans::certs (
  Target        $primary,
  Array[Target] $targets,
  Array[Target] $ovdb_targets = [],
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

  # Setup openvoxdb certs
  run_task('ovox::puppetdb', $ovdb_targets,
    'command' => 'ssl-setup',
  )
}
