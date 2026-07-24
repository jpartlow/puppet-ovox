require 'spec_helper'

describe 'ovox::get_pool_address' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  include_context('shared target maps')

  RSpec.shared_examples('get_pool_address') do |pool|
    it 'returns first lb_targets entry' do
      is_expected.to run.with_params(pool, h_target_map).and_return(lb_hostname)
    end

    it 'prefers override' do
      h_target_map[pool_param] = 'foo.lb.spec'
      is_expected.to run.with_params(pool, h_target_map).and_return('foo.lb.spec')
    end

    it 'returns an address if only override is set' do
      h_target_map[pool_param] = 'foo.lb.spec'
      h_target_map[lb_param] = []
      is_expected.to run.with_params(pool, h_target_map).and_return('foo.lb.spec')
    end

    it 'returns undef if neither set' do
      is_expected.to run.with_params(pool, s_target_map).and_return(nil)
    end
  end

  context 'compiler' do
    let(:lb_hostname) { h_target_map['compiler_lb_targets'].first.host }
    let(:lb_param) { 'compiler_lb_targets' }
    let(:pool_param) { 'compiler_pool_address' }
    include_examples('get_pool_address', 'compiler')
  end

  context 'ovdb' do
    let(:lb_hostname) { h_target_map['ovdb_lb_targets'].first.host }
    let(:lb_param) { 'ovdb_lb_targets' }
    let(:pool_param) { 'ovdb_pool_address' }
    include_examples('get_pool_address', 'ovdb')
  end
end
