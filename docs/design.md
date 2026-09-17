# Notes on module design

* hiera for configuration

The ovox::install plan has minimal configuration parameters up front.
Only the most crucial or commonly set parameters should be provided.

Any other customization can be provided directly in the cluster's
hiera data which is isolated under `./data/cluster/%{cluster_id}/` for
each `$install::cluster_id` execution of the install plan.

* openvox packages installed first via puppet-openvox_bootstrap

By default `$install::openvox_collection` packages are installed, but
version details can be configured separately through install plan
parameters.

* relies on existing modules to configure nodes

```
puppet-puppet
puppet-openvoxdb
puppetlabs-postgresql
puppetlabs-haproxy
...
```

* the [puppet-ov_role] module provides the role classes
* the [puppet-ov_profile] module classes provides the profile classes
  that serve as abstraction over the underlying configuration modules

Wherever possible, the profiles prefer inclusion over class
declaration and allow for hiera overrides to configure the system.

* one role per node set in the certificate

Each infrastructure node's role is set in a certificate extension
(currently *pp_role*), to make it simple to identify the roles of
infrastructure nodes, what role class to apply to infrastructure
nodes, and the cluster architecture (based on the set of
infrastructure node roles...).

* puppet apply used to configure

The principal configuration of the cluster is simply a loop around
cluster targets applying a single identified ov_role class per node,
informed by the generated and manually supplied hiera data for the
cluster (at `./data/cluster/%{cluster_id}`).

* TODO: optionally ovox-control may be placed on the primary to both
  maintain cluster infrastructure configuration after installation and
  to serve as a check of installation by way of puppet runs
  post-install

Whether using ovox-control or another control repo, maintenance of the
cluster infrastructure should simply be including
`ov_role::${trusted['extensions']['pp_role']}` while providing the
cluster's hiera data from `./data/cluster/%{cluster_id}`.

Alternately, you could the merge the hiera data and classes into your
own manifests/control-repo as desired.
