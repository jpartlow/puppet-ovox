require 'spec_helper'

describe 'ovox::compile_sans_for' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  include_context('shared target maps')

  it 'returns an empty array for a role without sans' do
    is_expected.to(
      run.
        with_params(
          'primary',
          m_target_map,
          {
            'compiler' => ['foo'],
          },
        ).
        and_return(
          []
        )
    )
  end

  context 'compiler' do
    let(:role) { 'compiler' }

    it 'returns compiler sans with pool address' do
      m_target_map['compiler_pool_address'] = 'foo.spec'
      m_target_map['compiler_lb_targets'] = []
      is_expected.to run.with_params(role, m_target_map).and_return(['foo.spec'])
    end

    it 'returns compiler sans with lbs' do
      is_expected.to run.with_params(role, m_target_map).and_return(['clb.spec'])
    end

    it 'returns compiler sans with additional sans' do
      m_target_map['compiler_lb_targets'] = []
      is_expected.to(
        run.
          with_params(
            role,
            m_target_map,
            {
              'compiler' => ['foo1.spec'],
              'ovdb'     => ['bar1.spec'],
            }
          ).
          and_return(['foo1.spec'])
      )
    end

    it 'returns compiler sans with all' do
      m_target_map['compiler_pool_address'] = 'foo.spec'
      is_expected.to(
        run.
          with_params(
            role,
            m_target_map,
            {
              'compiler' => ['foo1.spec'],
              'ovdb'     => ['bar1.spec'],
            }
          ).
          and_return(['foo.spec', 'clb.spec', 'foo1.spec'])
      )
    end
  end
end
