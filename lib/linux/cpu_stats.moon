insert: append = table

->
  f = io.open('/proc/stat', 'r')
  aggregate = f\read('*a')\split("\n")[1]
  f\close!
  fields = {}
  for idx, field in ipairs aggregate\split(' ')
    append fields, tonumber(field) if idx > 1
  user, nice, system, idle, iowait, irq, softirq, steal, guest, guest_nice = unpack fields
  non_idle = user + nice + system + irq
  total = idle + non_idle
  total, idle
