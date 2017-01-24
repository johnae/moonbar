-- just parses output from acpi -b
-- into percent, status and time_remaining

(output) ->
  acpi = output\split '\n'
  batt = ([line for line in *acpi when line\match '^Battery'])[1]
  if batt
    status = batt\match ':%s(%a+),'
    status = status\lower!
    percent = tonumber batt\match(',%s(%d+)%%')
    time_remaining = batt\match ',%s(%d+:%d+):%d+%s%a+'
    return status, percent, time_remaining

