# frozen_string_literal: true

$LOAD_PATH.unshift File.join(__dir__, 'lib')

require 'rspec-puppet'
require 'rspec-puppet-facts'
require 'ovox/tools'
require 'ovox/shared_contexts'

module KatRspec
  def self.fixture_path
    File.expand_path(File.join(__dir__, 'fixtures'))
  end

  def self.modulepath
    [
      # spec/fixtures/modules is where rspec-puppet autogenerates
      # a symlink for the module being tested
      File.join(fixture_path, 'modules'),
      # .modules is where bolt puts its modules (all of our dependencies)
      File.join(__dir__, '..', '.modules'),
    ]
  end
end

module BoltTargetInspect
  def inspect
    "#<Bolt::Target #{name}>"
  end
end

RSpec.configure do |c|
  # Include the Bolt .modules directory as part of the modulepath for
  # dependencies. Joined because rspec-puppet can only deal with a
  # multi-element modulepath as a string.
  c.module_path     = KatRspec.modulepath.join(File::PATH_SEPARATOR)
  c.manifest        = File.join(KatRspec.fixture_path, 'manifests', 'site.pp')
  c.environmentpath = File.join(Dir.pwd, 'spec', 'environments')
  c.facterdb_string_keys = true
  c.include(Ovox::SpecTools)
  # Since the default Ruby inspect calls inspect on attrs and
  # Bolt::Target has a deeply nested chain of attributes, an inspect
  # called during diff of rspec failures that involves Targets gets
  # obscured by huge blobs of nested attr data. This makes it difficult
  # to pin down the failure. Replacing the Target.inspect() behavior
  # while the suite is running avoids this.
  c.before(:suite) { Bolt::Target.prepend(BoltTargetInspect) }
end

require 'bolt_spec/plans'

RSpec.shared_context 'plan_init' do
  include BoltSpec::Plans

  # This should still execute before the before(:all)
  # See: https://rspec.info/features/3-12/rspec-core/hooks/around-hooks/
  around(:example) do |example|
    old_modpath = RSpec.configuration.module_path
    # This bit of insanity is due to the fact that rspec-puppet can only
    # deal with a module:path, while BoltSpec can only deal with a
    # [module, path]...
    RSpec.configuration.module_path = KatRspec.modulepath
    example.run
  ensure
    RSpec.configuration.module_path = old_modpath
  end

  before(:all) do
    # suppress warnings about constant redefinition in logging gem:
    # (logging-2.4.0/lib/logging.rb)
    verbosity = $VERBOSE
    $VERBOSE = nil
    BoltSpec::Plans.init
    $VERBOSE = verbosity
  end
end
