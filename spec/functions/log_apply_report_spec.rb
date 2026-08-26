require 'spec_helper'

describe 'ovox::log_apply_report' do
  include BoltSpec::BoltContext

  around(:each) do |example|
    in_bolt_context { example.run }
  end

  let(:empty_apply_result) do
    Bolt::ApplyResult.new(nil)
  end

  let(:logs) do
    [
      {
        'level'   => 'info',
        'time'    => '2026-11-08 13:38:01',
        'source'  => '/thing',
        'message' => 'a message',
        'file'    => '/a/file',
        'line'    => '10',
      },
    ]
  end

  let(:apply_result) do
    Bolt::ApplyResult.new(nil, report: { 'logs' => logs })
  end

  it 'runs and does nothing if there are no logs' do
    is_expected.to run.with_params(empty_apply_result).and_return(true)
  end

  it 'runs and prints logs' do
    expect_out_message

    is_expected.to run.with_params(apply_result).and_return(true)
  end
end
