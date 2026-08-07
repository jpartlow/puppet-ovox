# ovox

[OpenBolt] module for setting up [OpenVox] installations in different
layouts.

## Usage

Install the [OpenBolt] package on the runner workstation.

`bolt module install` to download additional module dependencies that
are not part of the openbolt package.

Prepare a params.json.

Prepare an inventory.yaml if your targets are not resolvable.
NOTE: target names must be resolvable as these will become the CN of
the certificates generated for the agents.

`bolt plan run ovox::install --params=@params.json`

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
