require 'spec_helper'

describe 'ovox::check_role_target_intersection' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  let(:role_map) do
    {
      'spec1' => [a_target('t1'), a_target('t2')],
      'spec2' => [a_target('t3'), a_target('t4')],
      'spec3' => [a_target('t5'), a_target('t6')],
      'conflict1' => [a_target('t5'), a_target('t3')],
      'conflict2' => [a_target('t7'), a_target('t6')],
    }
  end

  it 'raises an error when role is not in role_map' do
    is_expected.to(
      run.with_params('not-a-role', role_map)
        .and_raise_error(/Role 'not-a-role' not found/)
    )
  end

  it 'returns an empty array when no conflicts found' do
    is_expected.to(
      run.with_params('spec1', role_map).and_return([])
    )
  end

  it 'returns an array with errors when conflicts found' do
    is_expected.to(
      run.with_params('spec2', role_map).and_return(
        [
          "The spec2 hostnames should be unique, but were found in the conflict1 list: [t3]",
        ]
      )
    )
  end

  it 'may return multiple errors for multiple conflicts' do
    is_expected.to(
      run.with_params('spec3', role_map).and_return(
        [
          "The spec3 hostnames should be unique, but were found in the conflict1 list: [t5]",
          "The spec3 hostnames should be unique, but were found in the conflict2 list: [t6]",
        ]
      )
    )
  end
end
