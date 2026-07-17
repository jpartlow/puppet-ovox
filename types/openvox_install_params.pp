# Parameters defining OpenVox agent version for the
# ovox::install_openvox plan.
#
# Keys:
# - openvox_version: The version of OpenVox to install. If installing
#   a released version, major version must match openvox_collection,
#   or 'latest' to install latest version from collection.
# - openvox_collection: The collection of OpenVox to install from.
#   ('openvox7', 'openvox8', etc.).
# - openvox_released: Whether to install released packages from
#   the given openvox_collection via the system package manager,
#   or to download and install a pre-release openvox_version package
#   from the openvox_artifacts_url for dev testing.
# - openvox_artifacts_url: The URL to the OpenVox artifacts server.
#   Generally this can be skipped if the packages you are looking for
#   are on the artifacts.voxpupuli.org server.
type Ovox::Openvox_install_params = Struct[{
  Optional[openvox_version]       => Ovox::Openvox_version,
  Optional[openvox_collection]    => Ovox::Openvox_collection,
  Optional[openvox_released]      => Boolean,
  Optional[openvox_artifacts_url] => Optional[Stdlib::HTTPUrl],
}]
