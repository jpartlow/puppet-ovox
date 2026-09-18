# ovox

[OpenBolt] module for setting up [OpenVox] installations in different
layouts.

## Overview

The Bolt plans in this module are used to setup [OpenVox]
installations from a (usually) separate jumphost.

* hiera for configuration
* [puppet-openvox_bootstrap] installs openvox packages
* one role per node set in the certificate
* configuration is done using established modules
  * [puppet-puppet]
  * [puppet-openvoxdb]
  * [puppetlabs-postgresql]
  * [puppetlabs-haproxy]
* the [puppet-ov_role] module provides the role classes that tie a
  particular set of profile configuration classes to a particular
  target
* the [puppet-ov_profile] module classes provides the profile classes
  that serve as abstractions over the established configuration modules
* puppet apply is used to configure each node

### Installation Stages

The [ovox::install](./plans/install.pp) plan breaks down into the
following stages of execution:

#### Validation

Before any work is done on the given targets, the
[validate_architecture](./plans/subplans/validate_architecture.pp)
subplan checks that the roles assigned to targets form some kind of
valid architecture that the plan is capable of installing, otherwise
execution halts.

#### Openvox package installation

All openvox packages are installed first by the
[install_openvox](./plans/subplans/install_openvox.pp) subplan. This
allows certificate generation prior to configuration, and allows
installation of mixed versions of openvox services (including
pre-release packages) for testing scenarios. The
[puppet-openvox_bootstrap] module is used for installation here, and
version details can be specified by parameters to the install plan. By
default, `$install::openvox_collection` packages are installed.

#### Cluster configuration

The bulk of the work is done during the third stage when the
[configure](./plans/subplans/configure.pp) subplan is executed.

1. Targets are formally assigned a role
2. Hiera configuration is written for `$install::cluster_id` in the
   local ./data/cluster dir (see [Hiera](#hiera) below)
3. Configure puppet.conf and csr_attributes.yaml on infrastructure
   nodes.
 * puppet.conf server setting is set to the primary (principle
   openvox-server/ca node)
 * adds the role to the certificate via the [pp_role] certificate
   extension
4. Generate and sign infrastructure certificates
5. Each infrastructure node has the ov_role::${role} class applied
   to it, with parameter data coming from the above hiera data
6. If there are any exclusively agent targets, they get their
   puppet.conf server written to point to get_pool_address(),
   and set their caserver to the primary
7. Generate and sign agent certificates, if any
8. Validate agent runs on all nodes
9. Ensure agent service is set according to
   `$install::agent_service_running` and
   `$install::agent_service_enabled`.

## Usage

Install the [OpenBolt] package on the runner workstation.

From the root of the puppet-ovox module, run `bolt module install` to
download additional module dependencies that are not part of the
openbolt package.

Prepare a params.json.

Prepare an inventory.yaml if your targets are not resolvable.
NOTE: target names must be resolvable to one another as these will
become the CN of the certificates generated for the agents.

```
bolt plan run ovox::install --params=@params.json
```

### Installation Parameters

The key install parameters are:

* **cluster_id** - unique identifying string for the cluster. This is
  used to isolate generated hiera data for configuration (see
  [Hiera][#hiera] below).
* **primary_host** - the target that will provide the primary
  openvox-server/certificate-authority for the cluster.
* **ovdb_hosts** - the target(s) that will provide openvoxdb services
  for the cluster (defaults to `$install::primary_host`)
* **postgres_hosts** - the target that will provide postgresql
  services for the cluster (defaults to `$install::primary_host`)
* **compiler_hosts** - the targets that will provide additional
  openvox-server compiler services for the agent fleet.

If **compiler_hosts** are specified, then either
`$install::compiler_lb_hosts` should be set to a target on which an
haproxy load balancer will be built for the compilers, or
`$install::compiler_pool_address` should be set to the hostname of
some external load balancer solution for the compiler services.

Likewise, if **ovdb_hosts** has more than one target, then
`$install::ovdb_lb_hosts` or `$install::ovdb_pool_address` should be
set.

### Examples

#### Small

For a small architecture, the following parameters would be
sufficient to produce a single primary with openvox-server, openvoxdb
and postgresql services installed and configured:

```params.small.json
{
  "cluster_id": "ov-s",
  "primary_host": "primary-1.vm",
}
```

#### Medium

For a medium architecture, compilers are added:

```params.medium.json
{
  "cluster_id": "ov-m",
  "primary_host": "primary-1.vm",
  "compiler_hosts": [
    "compiler-1.vm",
    "compiler-2.vm"
  ],
  "compiler_lb_hosts": [clb-1.vm"],
  "agent_hosts": ["agent-1.vm"],
}
```

NOTE: the inclusion of **agent_hosts** is entirely optional, but does
allow an agent configured against the compiler load-balancer to
confirm catalog through the **compiler_hosts** during final
validation in the plan run...

#### Large

For a large architecture, the postgresql service is moved to its own
target:

```params.large.json
{
  "cluster_id": "ov-l",
  "primary_host": "primary-1.vm",
  "postgres_hosts": [
    "postgres-1.vm"
  ],
  "compiler_hosts": [
    "compiler-1.vm",
    "compiler-2.vm"
  ],
  "compiler_lb_hosts": ["clb-1.vm"],
  "agent_hosts": ["agent-1.vm"],
}
```

#### Huge

For a huge architecture, openvoxdb services are pulled out into their
own load-balanced group:

```params.large.json
{
  "cluster_id": "ov-h",
  "primary_host": "primary-1.vm",
  "ovdb_hosts": [
    "ovdb-1.vm",
    "ovdb-2.vm"
  ],
  "ovdb_lb_hosts": ["ovlb-1.vm"],
  "postgres_hosts": [
    "postgres-1.vm"
  ],
  "compiler_hosts": [
    "compiler-1.vm",
    "compiler-2.vm"
  ],
  "compiler_lb_hosts": ["clb-1.vm"],
  "agent_hosts": ["agent-1.vm"],
}
```
## Post installation

Maintenance of the cluster infrastructure could simply be including
`include ov_role::${trusted['extensions']['pp_role']}` on
infrastructure nodes while providing the generated cluster's hiera
data from `./data/cluster/%{cluster_id}` and including the [ov_role]
and [ov_profile] modules in the control repository config.

TODO: Adding an r10k profile to the primary role so that a control
repo can be placed during installation.

TODO: Providing an option for a separate ovox-control repo to maintain
infrastructure configuration post-installation. (Probably as an
additional environment_dir on the primary, with infrastructure set to
an 'ovox' environment...)

## Cluster architectures

[architectures.md](./docs/architectures.md)

Architecture of the cluster is based on target assignments to
the install plan's principal `$install::*_host(s)` parameters.

Primary profiles (currently for openvox-server, openvoxdb and
postgresql) can overlap targets, which allows for the progressive
scaling of primary services between small, large and huge
architectures. So **primary_host**, **ovdb_hosts** and
**postgres_hosts** can have the same or disjoint targets.

All other roles must be exclusive.

### Errors

If **compiler_hosts**, **compiler_lb_hosts** or **ovdb_lb_hosts**
targets overlap with any other hosts parameter, an error will be
thrown during validation and the plan will halt.

Every target has one role.

### Ambiguous architectures

It is possible to assign hosts in such a way that roles are still
valid, but the complexity of the configuration exceeds what the module
can automatically generate hiera data for.

As an example, setting two targets for **primary_host** (which is a
TargetSpec, and accepts an array...), or for **postgres_hosts**, are
both valid as far as the module being able to install packages and
assign roles to nodes, but exceeds its current ability to figure out
how to generate hiera data that correctly configures such an
installation.

These architectures are marked *ambiguous*. The plan can be run, but
you will need to add custom hiera data ahead of time to get them
configured such that the plan will succeed in the configuration phase.
(see [Hiera](#hiera) below)

See [Ovox::Architectures](./types/architectures.pp) for additional
discussion of custom, ambiguous and error architectures.

## Hiera

Each cluster's `$install::cluster_id` parameter defines a separate hiera
directory at `./data/cluster/%{cluster_id}` (see [hiera.yaml](./hiera.yaml) for the lookup rules).

The module generates the cluster's root `./data/cluster/%{cluster_id}`
directory during each run.

### Autoconfiguration

If the cluster architecture is a named or unambiguous custom arch,
then the module populates `./data/cluster/%{cluster_id}/ovox.yaml`
with general hiera data for the cluster, and
`./data/cluster/%{cluster_id}/role/%{role}.yaml` as needed to
configure all the services in the cluster.

These files may be automatically re-written and/or removed by the
module during each run of the installation plan.

### Manual configuration

Additional hiera config can be placed under
`./data/cluster/%{cluster_id}/custom/` to override any of this
configuration or otherwise customize the cluster. The module will not
touch any files under the custom directory.

#### Configuring ambiguous architectures

If the architecture is *ambiguous*, the module cannot auto-generate
hiera configuration because it cannot determine the key components
(multiple postgresql nodes, ambiguous primary roles, no pool address
for compilers, etc.). In this case, the hiera data can be set manually
as above prior to the installation run by adding
`./data/cluster/%{cluster_id}/custom/ovox.yaml`,
`./data/cluster/%{cluster_id}/custom/role/%{role}.yaml` and
`./data/cluster/%{cluster_id}/custom/node/%{trusted.certname}.yaml`
data as needed to supply the correct configuration for the cluster.

## Limitations

* airgapped environments (lacking Internet access) - installation of
  packages assumes that the target nodes can pull down packages
  (openvox and postgresql) from the Internet and will fail on
  airgapped targets unless local repositories have been configured to
  provide the necessary packages.
* ??? many other things?

## Platforms

Platform testing will be done in Github Actions.

## Terms

* **Primary** - The principal openvox-server host in the cluster that
  serves both as the certificate authority and compiler for
  **infrastructure** catalogs.
* **Infrastructure Nodes** - Nodes in the cluster that provide openvox
  services. As opposed to the agent fleet that gets catalogs from the
  openvox infrastructure.
* **Compiler** - An openvox-server host that serves to scale out
  catalog compilation for the agent fleet.

## Reference

See [REFERENCE.md](./REFERENCE.md) for function, task and plan
details.

## Tests

A local ruby environment (package or `rbenv` provided, for example) is
required.

To run the specs:

* `bundle install`
* `bundle exec bolt module install`
* `bundle exec rspec`

## TODO

* wire up flag to ignore ambiguity warnings for non-interactive
  workflows
* lb needs configurable maxconn for front and backends.
* secure pdb comms
  * puppetdbs should have an allowlist for the nodes that connect to
    them (ovlbs, compilers, primary)
* r10k integration
* wire up configuration needed to access unmanaged postgres
* (maybe?) ovdb lb simple status health check via ssl.
* determine other core configuration parameters to wire through from
  install plan parameters, versus configuration that should be left to
  manual hiera `./data/cluster/%{cluster_id}/custom` overrides for
  edge cases.
* puppet_operational_dashboards
* frontends
* tuning
* upgrading
* ???

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
[openvox]: https://docs.openvoxproject.org/
[pp_role]: (https://docs.openvoxproject.org/openvox/latest/ssl_attributes_extensions.html)
[puppet-openvox_bootstrap]: https://github.com/voxpupuli/puppet-openvox_bootstrap
[puppet-openvoxdb]: https://github.com/voxpupuli/puppet-openvoxdb
[puppet-ov_role]: https://github.com/jpartlow/puppet-ov_role
[puppet-ov_profile]: https://github.com/jpartlow/puppet-ov_profile
[puppet-puppet]: https://github.com/theforeman/puppet-puppet
[puppetlabs-postgresql]: https://github.com/puppetlabs/puppetlabs-postgresql
[puppetlabs-haproxy]: https://github.com/puppetlabs/puppetlabs-haproxy
