:round = math
:insert = table

cpu_total = 0
cpu_idle = 0

cpu_stats = ->
  f = io.open('/proc/stat', 'r')
  aggregate = f\read('*a')\split("\n")[1]
  f\close!
  fields = {}
  for idx, field in ipairs aggregate\split(' ')
    insert fields, tonumber(field) if idx > 1
  user, nice, system, idle, iowait, irq, softirq, steal, guest, guest_nice = unpack fields
  non_idle = user + nice + system + irq
  total = idle + non_idle
  total, idle

->
  prev_total, prev_idle = cpu_total, cpu_idle
  cpu_total, cpu_idle = cpu_stats!
  unless type(cpu_total) == 'number'
    cpu_total = 0
  unless type(cpu_idle) == 'number'
    cpu_idle = 0
  round(((cpu_total-prev_total)-(cpu_idle-prev_idle))/(cpu_total-prev_total)*100,2)
