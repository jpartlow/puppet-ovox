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
  # XXX: Why the heck am I doing this reload? Ok, so there's a race
  # condition in openvox-server startup that is popping up when I run
  # test cycles against very modest vms (2cpu, 4GB primary) on my
  # workstation. It's the permissions of
  # /etc/puppetlabs/puppet/ssl/certs/ca.pem, which comes up 0640 under
  # some load conditions, and 0644 normally. This matters because the
  # eventual configuration of the Postgresql service on the primary
  # (by the puppet-openvoxdb, puppetlabs-postgresql modules) expects
  # to be able to read ca.pem, and it can't if it's 0640, so postgres
  # is unresponsive for ssl coms. The reason looks to be a race
  # between the openvox-server certificate-authority service and the
  # jruby-puppet-service. The ca service actually creates the
  # /etc/puppetlabs/puppetserver/ca/ca_crt.pem and copies it to
  # /etc/puppetlabs/puppet/ssl/certs/ca.pem. But the systemd
  # puppetserver.service UMask=027, so it's created 0640. Normally,
  # the ca service completes first and then jruby-puppet-service
  # finishes initializing a jruby puppet instance, in the process of
  # which Puppet runs its own settings catalog managing localcacert
  # /etc/puppetlabs/puppet/ssl/certs/ca.pem to 0644. But if for
  # whatever reason load on the vm is such that the jruby process
  # finishes initializing before the ca, there is no file to adjust
  # yet, and the ca.pem is left 0640, and Postgresql is sad. This
  # persists until the jruby pool adds or rotates, or the puppetserver
  # is reloaded. (Most likely, real puppetservers have enough cpu/ram,
  # jrubies in their pool such that there's always at least one that
  # finishes after ca bootstrap? Or there's generally always a reload
  # or jruby cycle before someone gets around to configuring
  # postgres...so it's only cropping up in this kind of tightly
  # managed installation process on small test vms...)
  #
  # At any rate, I need to open a ticket for this for openvox-server
  # and work out a patch. A simple patch suggested by Claude was to
  # add a (ks-file/set-perms localcacert public-key-perms) to
  # openvox-server's certificate-authority.clj retrieve-ca-crt!
  # function.
  run_command('systemctl reload puppetserver', $primary)
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

    run_task('ovox::puppet_ssl', $targets,
      'command' => 'download',
    )
  } else {
    out::message('No targets, nothing to sign.')
  }

  # Setup openvoxdb certs
  run_task('ovox::puppetdb', $ovdb_targets,
    'command' => 'ssl-setup',
  )
}
