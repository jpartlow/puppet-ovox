# ovox

[OpenBolt] module for setting up [OpenVox] installations in different
layouts.

## Design

* hiera for configuration

The ovox::install plan has minimal configuration parameters up front.
Only the most crucial or commonly set parameters should be provided.

Any other customization can be provided directly in the cluster's
hiera data (see below).

* openvox packages installed first via puppet-openvox_bootstrap
* relies on existing modules to configure nodes

```
theforeman-puppet
puppet-openvoxdb
puppetlabs-postgresql
...
```

* the puppet-ov_role module provides the role classes
* the puppet-ov_profile module classes provides the profile classes
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

* optionally ovox-control may be placed on the primary to both
  maintain cluster infrastructure configuration after installation and
  to serve as a check of installation by way of puppet runs
  post-install

Whether using ovox-control or another control repo, maintenance of the
cluster infrastructure should simply be including
`ov_role::${trusted['extensions']['pp_role']}` while providing the
cluster's hiera data from `./data/cluster/%{cluster_id}`.

Alternately, merge the hiera data and classes into your own
manifests/control-repo as desired.

### Stages

The ovox::install plan breaks down into the following stages of
execution:

#### Validation


#### Openvox package installation

#### Cluster configuration

## Usage

Install the [OpenBolt] package on the runner workstation.

`bolt module install` to download additional module dependencies that
are not part of the openbolt package.

Prepare a params.json.

Prepare an inventory.yaml if your targets are not resolvable.
NOTE: target names must be resolvable as these will become the CN of
the certificates generated for the agents.

`bolt plan run ovox::install --params=@params.json`

## Cluster architectures

[architectures.md](./docs/architectures.md)

## Hiera

Each cluster's *cluster_id* parameter defines a separate hiera
directory at `./data/cluster/%{cluster_id}` (see [hiera.yaml](./hiera.yaml)).
The module generates the cluster's root `./data/cluster/%{cluster_id}`
directory during each run.

### Autoconfiguration

If the cluster architecture is a named or unambiguous custom arch,
then the module populates `./data/cluster/%{cluster_id}/ovox.yaml`
with general hiera data for the cluster, and
`./data/cluster/%{cluster_id}/role/%{role}.yaml` as needed to configure all
the services in the cluster.

These files may be automatically re-written and/or removed by the
module during each run of the installation plan.

### Manual configuration

Additional hiera config can be placed under
`./data/cluster/%{cluster_id}/custom/` to override any of this configuration
or otherwise customize the cluster. The module will not touch any
files under the custom directory.

#### Ambiguous architectures

If the architecture is *ambiguous*, the module cannot auto-generate
hiera configuration because it can't determine the key components
(multiple postgresql nodes, ambiguous primary roles, no pool address
for compilers, etc.). In this case, the hiera data can be set manually
as above prior to the installation run by adding
`./data/cluster/%{cluster_id}/custom/ovox.yaml`,
`./data/cluster/%{cluster_id}/custom/role/%{role}.yaml` and
`./data/cluster/%{cluster_id}/custom/node/%{trusted.certname}.yaml` data as needed to
supply the correct configuration for the cluster.

## Platforms

## Reference

## Tests

A local ruby environment (package or `rbenv` provided, for example) is
required.

To run the specs:

* `bundle install`
* `bundle exec bolt module install`
* `bundle exec rspec`

## License

Copyright (C) 2026 Joshua Partlow

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

[openbolt]: https://github.com/OpenVoxProject/openbolt/
