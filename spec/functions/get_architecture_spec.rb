require 'spec_helper'

describe 'ovox::get_architecture' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  include_context('shared target maps')

  it 'returns tiny for a tiny arch' do
    is_expected.to run.with_params(t_target_map).and_return('tiny')
  end

  it 'returns small for a small arch' do
    is_expected.to run.with_params(s_target_map).and_return('small')
  end

  it 'returns medium for a medium arch' do
    is_expected.to run.with_params(m_target_map).and_return('medium')
  end

  it 'returns large for a large arch' do
    is_expected.to run.with_params(l_target_map).and_return('large')
  end

  it 'returns huge for a huge arch' do
    is_expected.to run.with_params(h_target_map).and_return('huge')
  end

  context 'with unmanaged postgres' do
    it 'returns large for a large arch'do
      is_expected.to(
        run.with_params(unmanaged_postgres(l_target_map)).
          and_return('large')
      )
    end

    it 'returns huge for a huge arch'do
      is_expected.to(
        run.with_params(unmanaged_postgres(h_target_map)).
          and_return('huge')
      )
    end
  end

  # Some examples of custom architectures.
  context 'custom' do
    it 'returns custom for tiny with compilers' do
      t_target_map['compiler_targets'] << compiler1
      t_target_map['compiler_pool_address'] = 'compiler1.spec'
      is_expected.to(
        run.with_params(t_target_map).
          and_return('custom')
      )
    end

    it 'returns custom for large without compilers' do
      l_target_map['compiler_targets'] = []
      is_expected.to(
        run.with_params(l_target_map).
          and_return('custom')
      )
    end

    it 'returns custom for a small with unmanaged postgres' do
      is_expected.to(
        run.with_params(unmanaged_postgres(s_target_map)).
          and_return('custom')
      )
    end
  end

  context 'ambiguous' do
    it 'returns ambiguous for more than one postgres' do
      l_target_map['postgres_targets'] << a_target('postgres2.spec')
      is_expected.to(
        run.with_params(l_target_map).
          and_return('ambiguous')
      )
    end
  end

  context 'errors' do
    it 'returns error for role conflicts' do
      l_target_map['compiler_targets'] << clb
      is_expected.to(
        run.with_params(l_target_map).
          and_return('error')
      )
    end
  end
end
