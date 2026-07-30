require 'spec_helper'

describe 'plan: ovox::subplans::validate_architecture' do
  include_context 'plan_init'

  RSpec.shared_examples('run arch plan') do
    it 'returns a target map' do
      expect_out_message

      result = run_plan('ovox::subplans::validate_architecture', params)

      expect(result.ok?).to(eq(true), result.value.to_s)
      expect(result.value).to eq(target_map)
    end
  end

  include_context 'shared target maps'

  context 'tiny' do
    let(:params) { t_params }
    let(:target_map) { t_target_map }

    include_examples('run arch plan')
  end

  context 'small' do
    let(:params) { s_params }
    let(:target_map) { s_target_map }

    include_examples('run arch plan')
  end

  context 'medium' do
    let(:params) { m_params }
    let(:target_map) { m_target_map }

    include_examples('run arch plan')
  end

  context 'large' do
    let(:params) { l_params }
    let(:target_map) { l_target_map }

    include_examples('run arch plan')
  end

  context 'huge' do
    let(:params) { h_params }
    let(:target_map) { h_target_map }

    include_examples('run arch plan')
  end

  context 'custom' do
    let(:params) do
      l_params['ovdb_hosts'] = [postgres.to_s]
      l_params
    end
    let(:target_map) do
      l_target_map['ovdb_targets'] = [postgres]
      l_target_map
    end

    include_examples('run arch plan')
  end
end
