# Architectures

This document is intended to provide labels for a few possible
architectures of OpenVox services that can be configured using this
module.

The differences between the named architectures are principally ones
of scale, where given a primary of the same capacity, an increase in
architectural size should allow for more agents.

The details there are also vague, though, since we're not specifying x
number of compilers for example.

## Tiny

Simplest configuration with just an openvox-server/ca primary and a
cloud of agents.

TODO: Diagram

## Small

Simplest full service set, with openvox-server, openvoxdb and
postgresql all on the primary, and an agent cloud with no compilers
between.

The difference between small and tiny isn't really scale so much as
richness of available services (openvoxdb is present). All else being
equal, a tiny primary might well serve more catalogs than a small
primary using the same hardware given that openvox-server wouldn't be
competing with openvoxdb/postgres for resources.

TODO: Diagram

## Medium

Scales out from small by providing an array of load balanced
openvox-server compilers between the agents and the primary server.
The ca still resides with the first openvox-server instance on the
primary.

TODO: Diagram

## Large

Pulls PostgreSQL out to its own node so openvox-server and openvoxdb
aren't contending with it.

TODO: Diagram

## Huge

Also pulls out openvoxdb into a load-balanced array of nodes to allow
scaling of openvoxdb as well.

TODO: Diagram

## Custom

A catch all category for some distribution of the services that
doesn't fit into any of the above patterns. Some of these might be
viable, but might not be the best choice architecturally.

For example, a small primary could instead have postgres pulled out to
its own node, but for scaling, you're more likely to benefit from
adding compilers first...
