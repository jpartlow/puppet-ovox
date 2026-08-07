require 'spec_helper'

describe 'plan: ovox::subplans::certs' do
  include_context('plan_init')
  include_context('shared target maps')

  let(:params) do
    {
      'primary' => primary,
      'targets' => [compiler1, compiler2]
    }
  end

  it 'runs' do
    allow_apply
    expect_task('ovox::puppet_ssl').
      with_targets([compiler1, compiler2]).
      with_params(
        {
          'command'            => 'generate',
          'allow_existing_csr' => true,
        }
      )
    expect_task('ovox::puppetserver_ca').
      with_targets(primary).
      with_params(
        {
          'command'         => 'sign',
          'certnames'       => ['compiler1.spec', 'compiler2.spec'],
          'check_if_signed' => true,
          'format'          => 'json',
        }
      )

    result = run_plan('ovox::subplans::certs', params)
    expect(result.ok?).to(eq(true), result.value.to_s)
  end

  it 'runs with empty targets' do
    allow_apply
    expect_out_message

    params['targets'] = []

    result = run_plan('ovox::subplans::certs', params)
    expect(result.ok?).to(eq(true), result.value.to_s)
  end
end
