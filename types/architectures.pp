# Enumeration of OpenVox cluster architecture types.
type Ovox::Architectures = Enum[
  # Named:
  # See docs/architectures.md for details of the named architectures.
  'tiny',
  'small',
  'medium',
  'large',
  'huge',

  # Custom:
  # Custom refers to valid, unambiguous architectures that do not fit
  # one of the above named architectures, but for which the module can
  # still autogenerate hiera configuration.
  'custom',

  # Exception cases:
  # Ambiguous refers to all cases that do not throw errors, but which
  # have role ambiguities that prevent the module from autogenerating
  # hiera configuration data. Installation can proceed, so long as
  # manual hiera data is provided prior to the run.
  #
  # See ovox::validate_architecture() for definitions of ambiguous
  # cases.
  #
  # See the README.md for information on manual hiera configuration.
  'ambiguous',
  # Architecture has conflicting roles and installation will abort
  # in the validation stage.
  'error',
]
