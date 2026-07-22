require 'spec_helper'

describe 'ovox::derive_role_map' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  it 'generates a role_map'
end
