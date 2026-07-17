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

  it 'returns custom for strange things' do
    t_target_map['compiler_targets'] << compiler1
    is_expected.to(
      run.with_params(t_target_map).
        and_return('custom')
    )

    l_target_map['compiler_targets'] = []
    is_expected.to(
      run.with_params(l_target_map).
        and_return('custom')
    )

    is_expected.to(
      run.with_params(unmanaged_postgres(s_target_map)).
        and_return('custom')
    )
  end
end
