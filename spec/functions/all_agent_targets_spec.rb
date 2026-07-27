require 'spec_helper'

describe 'ovox::all_agent_targets' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  include_context('shared target maps')

  it 'returns agent list for a tiny arch' do
    $agents = call_function('ovox::all_agent_targets', t_target_map)
    expect($agents).to match_array(
      [
        primary,
        agent,
      ]
    )
  end

  it 'returns agent list for a small arch' do
    $agents = call_function('ovox::all_agent_targets', s_target_map)
    expect($agents).to match_array(
      [
        primary,
        agent,
      ]
    )
  end

  it 'returns agent list for a medium arch' do
    $agents = call_function('ovox::all_agent_targets', m_target_map)
    expect($agents).to match_array(
      [
        primary,
        compiler1,
        compiler2,
        clb,
        agent,
      ]
    )
  end

  it 'returns agent list for a large arch' do
    $agents = call_function('ovox::all_agent_targets', l_target_map)
    expect($agents).to match_array(
      [
        primary,
        postgres,
        compiler1,
        compiler2,
        clb,
        agent,
      ]
    )
  end

  it 'returns agent list for a huge arch' do
    $agents = call_function('ovox::all_agent_targets', h_target_map)
    expect($agents).to match_array(
      [
        primary,
        ovdb1,
        ovdb2,
        ovdblb,
        postgres,
        compiler1,
        compiler2,
        clb,
        agent,
      ]
    )
  end
end
