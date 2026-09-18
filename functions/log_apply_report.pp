# Log the report from an ApplyResult in a human readable format.
#
# @param ar The ApplyResult to log.
# @return True on completion.
function ovox::log_apply_report(
  ApplyResult $ar
) {
  $logs = ($ar.report() =~ Undef) ? {
    true    => [],
    default => $ar.report()['logs'],
  }
  $logs.sort |$a,$b| {
    compare($a['time'], $b['time'])
  }.each |$l| {
    $ts = Timestamp($l['time'])

    $t = ($l['source'] == 'Puppet') ? {
      true    => '[%<ts>s] %<level>s: %<msg>s',
      default => '[%<ts>s] %<level>s: %<source>s: %<msg>s',
    }
    $template = empty($l['file']) ? {
      true    => $t,
      default => "${t}\n  (%<file>s:%<line>s)",
    }
    $str = sprintf($template,
      {
        'ts'     => $ts.strftime('%Y%m%mT%H:%M:%S.%L'),
        'source' => $l['source'],
        'msg'    => $l['message'],
        'file'   => $l['file'],
        'line'   => $l['line'],
        'level'  => ($l['level'] == 'err') ? {
          true    => 'error',
          default => $l['level'],
        }.capitalize(),
      }
    )
    out::message($str)
  }
  true
}
